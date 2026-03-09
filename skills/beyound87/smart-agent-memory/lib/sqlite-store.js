/**
 * SQLite Storage Backend (optional upgrade)
 * Auto-detected when better-sqlite3 is installed.
 * Provides FTS5 full-text search + ACID transactions.
 */

'use strict';
const path = require('path');
const fs = require('fs');

let Database;
try {
  Database = require('better-sqlite3');
} catch {
  Database = null;
}

function isAvailable() {
  return Database !== null;
}

class SqliteStore {
  constructor(memoryDir) {
    if (!Database) throw new Error('better-sqlite3 not installed');

    this.memoryDir = memoryDir;
    this.dataDir = path.join(memoryDir, '.data');
    this.archiveDir = path.join(memoryDir, '.archive');
    this.indexFile = path.join(memoryDir, '.index.json');

    // Ensure dirs
    for (const d of [memoryDir, this.dataDir, this.archiveDir,
      path.join(memoryDir, 'lessons'), path.join(memoryDir, 'decisions'),
      path.join(memoryDir, 'people'), path.join(memoryDir, 'reflections')]) {
      fs.mkdirSync(d, { recursive: true });
    }

    const dbPath = path.join(this.dataDir, 'memory.db');
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this._initSchema();
    this.index = this._loadIndex();
  }

  _initSchema() {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS facts (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        tags TEXT DEFAULT '[]',
        source TEXT DEFAULT 'conversation',
        confidence REAL DEFAULT 1.0,
        createdAt TEXT NOT NULL,
        lastAccessed TEXT NOT NULL,
        accessCount INTEGER DEFAULT 1,
        expiresAt TEXT,
        supersededBy TEXT
      );

      CREATE TABLE IF NOT EXISTS lessons (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        context TEXT NOT NULL,
        outcome TEXT NOT NULL,
        insight TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        appliedCount INTEGER DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS entities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        entityType TEXT NOT NULL,
        attributes TEXT DEFAULT '{}',
        firstSeen TEXT NOT NULL,
        lastUpdated TEXT NOT NULL,
        factIds TEXT DEFAULT '[]'
      );
    `);

    // FTS5 for facts
    try {
      this.db.exec(`
        CREATE VIRTUAL TABLE IF NOT EXISTS facts_fts USING fts5(
          id, content, tags, tokenize='unicode61'
        );
      `);
    } catch {} // Already exists or FTS5 not compiled (rare)

    // FTS5 for lessons
    try {
      this.db.exec(`
        CREATE VIRTUAL TABLE IF NOT EXISTS lessons_fts USING fts5(
          id, action, context, insight, tokenize='unicode61'
        );
      `);
    } catch {}
  }

  _loadIndex() {
    try {
      return JSON.parse(fs.readFileSync(this.indexFile, 'utf8'));
    } catch {
      return { lastGC: null, lastReflection: null, stats: {} };
    }
  }

  _saveIndex() {
    fs.writeFileSync(this.indexFile, JSON.stringify(this.index, null, 2));
  }

  _id() {
    return require('crypto').randomBytes(6).toString('hex');
  }

  _now() {
    return new Date().toISOString();
  }

  // ══════════════════════════════════════════════════════════════════════
  // FACTS
  // ══════════════════════════════════════════════════════════════════════

  remember(content, { tags = [], source = 'conversation', confidence = 1.0, expiresInDays = null } = {}) {
    const id = this._id();
    const now = this._now();
    const expiresAt = expiresInDays ? new Date(Date.now() + expiresInDays * 86400000).toISOString() : null;
    const tagsJson = JSON.stringify(tags);

    this.db.prepare(`
      INSERT INTO facts (id, content, tags, source, confidence, createdAt, lastAccessed, accessCount, expiresAt)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
    `).run(id, content, tagsJson, source, confidence, now, now, expiresAt);

    // FTS index
    try {
      this.db.prepare('INSERT INTO facts_fts (id, content, tags) VALUES (?, ?, ?)').run(id, content, tags.join(' '));
    } catch {}

    // Markdown daily log
    this._appendDailyLog(`- **[${id}]** ${content}${tags.length ? ' `' + tags.join('`, `') + '`' : ''}`);

    return { id, content, tags, source, confidence, createdAt: now, lastAccessed: now, accessCount: 1, expiresAt, supersededBy: null };
  }

  recall(query, { limit = 10, tags = null, minConfidence = 0 } = {}) {
    const now = this._now();
    let rows;

    // Try FTS5 first, fallback to LIKE if no results or error
    try {
      rows = this.db.prepare(`
        SELECT f.*, rank FROM facts f
        JOIN facts_fts fts ON f.id = fts.id
        WHERE facts_fts MATCH ?
        AND f.confidence >= ?
        AND (f.expiresAt IS NULL OR f.expiresAt > ?)
        AND f.supersededBy IS NULL
        ORDER BY rank
        LIMIT ?
      `).all(query, minConfidence, now, limit * 3);
    } catch {
      rows = [];
    }

    // Fallback to LIKE for CJK/mixed content or when FTS5 misses
    if (rows.length === 0) {
      const terms = query.split(/\s+/).filter(Boolean);
      if (terms.length > 0) {
        const where = terms.map(() => 'f.content LIKE ?').join(' AND ');
        const params = terms.map(t => `%${t}%`);
        rows = this.db.prepare(`
          SELECT f.* FROM facts f
          WHERE ${where}
          AND f.confidence >= ?
          AND (f.expiresAt IS NULL OR f.expiresAt > ?)
          AND f.supersededBy IS NULL
          ORDER BY f.createdAt DESC
          LIMIT ?
        `).all(...params, minConfidence, now, limit * 3);
      }
    }

    // Parse and filter
    let results = rows.map(r => ({
      id: r.id, content: r.content, tags: JSON.parse(r.tags || '[]'),
      source: r.source, confidence: r.confidence,
      createdAt: r.createdAt, lastAccessed: r.lastAccessed,
      accessCount: r.accessCount, expiresAt: r.expiresAt, supersededBy: r.supersededBy,
    }));

    if (tags) {
      results = results.filter(f => tags.every(t => f.tags.includes(t)));
    }

    results = results.slice(0, limit);

    // Update access stats
    const update = this.db.prepare('UPDATE facts SET lastAccessed = ?, accessCount = accessCount + 1 WHERE id = ?');
    const tx = this.db.transaction(() => {
      for (const f of results) update.run(now, f.id);
    });
    tx();

    return results;
  }

  getFact(id) {
    const r = this.db.prepare('SELECT * FROM facts WHERE id = ?').get(id);
    if (!r) return null;
    return { ...r, tags: JSON.parse(r.tags || '[]') };
  }

  listFacts({ tags = null, limit = 50, includeSuperseded = false } = {}) {
    let query = 'SELECT * FROM facts WHERE 1=1';
    if (!includeSuperseded) query += ' AND supersededBy IS NULL';
    query += ' ORDER BY createdAt DESC LIMIT ?';

    let results = this.db.prepare(query).all(limit).map(r => ({ ...r, tags: JSON.parse(r.tags || '[]') }));

    if (tags) {
      results = results.filter(f => tags.some(t => f.tags.includes(t)));
    }
    return results;
  }

  supersede(oldId, newContent, opts = {}) {
    const newFact = this.remember(newContent, opts);
    this.db.prepare('UPDATE facts SET supersededBy = ? WHERE id = ?').run(newFact.id, oldId);
    return newFact;
  }

  forget(id) {
    const changes = this.db.prepare('DELETE FROM facts WHERE id = ?').run(id).changes;
    try { this.db.prepare('DELETE FROM facts_fts WHERE id = ?').run(id); } catch {}
    return changes > 0;
  }

  forgetStale({ days = 30, minAccessCount = 1 } = {}) {
    const cutoff = new Date(Date.now() - days * 86400000).toISOString();
    const result = this.db.prepare(`
      DELETE FROM facts
      WHERE lastAccessed < ? AND accessCount <= ? AND supersededBy IS NULL
    `).run(cutoff, minAccessCount);
    return result.changes;
  }

  // ══════════════════════════════════════════════════════════════════════
  // LESSONS
  // ══════════════════════════════════════════════════════════════════════

  learn(action, context, outcome, insight) {
    const id = this._id();
    const now = this._now();

    this.db.prepare(`
      INSERT INTO lessons (id, action, context, outcome, insight, createdAt, appliedCount)
      VALUES (?, ?, ?, ?, ?, ?, 0)
    `).run(id, action, context, outcome, insight, now);

    try {
      this.db.prepare('INSERT INTO lessons_fts (id, action, context, insight) VALUES (?, ?, ?, ?)').run(id, action, context, insight);
    } catch {}

    // Markdown
    const filename = `${now.slice(0, 10)}-${id}.md`;
    const md = `# ${action}\n\n**Context:** ${context}\n**Outcome:** ${outcome}\n**Insight:** ${insight}\n**Date:** ${now.slice(0, 10)}\n**ID:** ${id}\n`;
    fs.writeFileSync(path.join(this.memoryDir, 'lessons', filename), md);

    return { id, action, context, outcome, insight, createdAt: now, appliedCount: 0 };
  }

  getLessons({ context = null, outcome = null, limit = 10 } = {}) {
    let query = 'SELECT * FROM lessons WHERE 1=1';
    const params = [];
    if (context) { query += ' AND context LIKE ?'; params.push(`%${context}%`); }
    if (outcome) { query += ' AND outcome = ?'; params.push(outcome); }
    query += ' ORDER BY createdAt DESC LIMIT ?';
    params.push(limit);
    return this.db.prepare(query).all(...params);
  }

  applyLesson(id) {
    this.db.prepare('UPDATE lessons SET appliedCount = appliedCount + 1 WHERE id = ?').run(id);
  }

  // ══════════════════════════════════════════════════════════════════════
  // ENTITIES
  // ══════════════════════════════════════════════════════════════════════

  trackEntity(name, entityType, attributes = {}) {
    const now = this._now();
    const existing = this.db.prepare('SELECT * FROM entities WHERE name = ? AND entityType = ?').get(name, entityType);

    if (existing) {
      const merged = { ...JSON.parse(existing.attributes || '{}'), ...attributes };
      this.db.prepare('UPDATE entities SET attributes = ?, lastUpdated = ? WHERE id = ?').run(JSON.stringify(merged), now, existing.id);
      const updated = { ...existing, attributes: merged, lastUpdated: now, factIds: JSON.parse(existing.factIds || '[]') };
      this._writeEntityMd(updated);
      return updated;
    }

    const id = this._id();
    this.db.prepare(`
      INSERT INTO entities (id, name, entityType, attributes, firstSeen, lastUpdated, factIds)
      VALUES (?, ?, ?, ?, ?, ?, '[]')
    `).run(id, name, entityType, JSON.stringify(attributes), now, now);

    const entity = { id, name, entityType, attributes, firstSeen: now, lastUpdated: now, factIds: [] };
    this._writeEntityMd(entity);
    return entity;
  }

  getEntity(name, entityType = null) {
    let r;
    if (entityType) {
      r = this.db.prepare('SELECT * FROM entities WHERE name = ? AND entityType = ?').get(name, entityType);
    } else {
      r = this.db.prepare('SELECT * FROM entities WHERE name = ?').get(name);
    }
    if (!r) return null;
    return { ...r, attributes: JSON.parse(r.attributes || '{}'), factIds: JSON.parse(r.factIds || '[]') };
  }

  listEntities(entityType = null) {
    let rows;
    if (entityType) {
      rows = this.db.prepare('SELECT * FROM entities WHERE entityType = ? ORDER BY lastUpdated DESC').all(entityType);
    } else {
      rows = this.db.prepare('SELECT * FROM entities ORDER BY lastUpdated DESC').all();
    }
    return rows.map(r => ({ ...r, attributes: JSON.parse(r.attributes || '{}'), factIds: JSON.parse(r.factIds || '[]') }));
  }

  linkFactToEntity(entityName, factId) {
    const r = this.db.prepare('SELECT id, factIds FROM entities WHERE name = ?').get(entityName);
    if (r) {
      const ids = JSON.parse(r.factIds || '[]');
      if (!ids.includes(factId)) {
        ids.push(factId);
        this.db.prepare('UPDATE entities SET factIds = ?, lastUpdated = ? WHERE id = ?').run(JSON.stringify(ids), this._now(), r.id);
      }
    }
  }

  updateEntity(name, entityType, attributes) {
    const r = this.db.prepare('SELECT * FROM entities WHERE name = ? AND entityType = ?').get(name, entityType);
    if (!r) return null;
    const merged = { ...JSON.parse(r.attributes || '{}'), ...attributes };
    this.db.prepare('UPDATE entities SET attributes = ?, lastUpdated = ? WHERE id = ?').run(JSON.stringify(merged), this._now(), r.id);
    const updated = { ...r, attributes: merged, lastUpdated: this._now(), factIds: JSON.parse(r.factIds || '[]') };
    this._writeEntityMd(updated);
    return updated;
  }

  _writeEntityMd(entity) {
    const dir = entity.entityType === 'person' ? 'people' : 'decisions';
    const filename = `${entity.name.toLowerCase().replace(/\s+/g, '-')}.md`;
    const attrs = Object.entries(entity.attributes).map(([k, v]) => `- **${k}:** ${v}`).join('\n');
    const md = `# ${entity.name}\n**Type:** ${entity.entityType}\n**First seen:** ${entity.firstSeen.slice(0, 10)}\n**Last updated:** ${entity.lastUpdated.slice(0, 10)}\n\n${attrs || '_(no attributes)_'}\n`;
    try { fs.writeFileSync(path.join(this.memoryDir, dir, filename), md); } catch {}
  }

  // ══════════════════════════════════════════════════════════════════════
  // DAILY LOG
  // ══════════════════════════════════════════════════════════════════════

  _appendDailyLog(line) {
    const today = new Date().toISOString().slice(0, 10);
    const logFile = path.join(this.memoryDir, `${today}.md`);
    if (!fs.existsSync(logFile)) {
      fs.writeFileSync(logFile, `# ${today}\n\n## Facts\n\n`);
    }
    fs.appendFileSync(logFile, line + '\n');
  }

  // ══════════════════════════════════════════════════════════════════════
  // STATS
  // ══════════════════════════════════════════════════════════════════════

  stats() {
    const now = Date.now();
    const dayMs = 86400000;

    const total = this.db.prepare('SELECT COUNT(*) as c FROM facts').get().c;
    const active = this.db.prepare('SELECT COUNT(*) as c FROM facts WHERE supersededBy IS NULL').get().c;

    const hot7 = new Date(now - 7 * dayMs).toISOString();
    const warm30 = new Date(now - 30 * dayMs).toISOString();
    const hot = this.db.prepare('SELECT COUNT(*) as c FROM facts WHERE supersededBy IS NULL AND createdAt > ?').get(hot7).c;
    const warm = this.db.prepare('SELECT COUNT(*) as c FROM facts WHERE supersededBy IS NULL AND createdAt <= ? AND createdAt > ?').get(hot7, warm30).c;
    const cold = this.db.prepare('SELECT COUNT(*) as c FROM facts WHERE supersededBy IS NULL AND createdAt <= ?').get(warm30).c;

    const lessons = this.db.prepare('SELECT COUNT(*) as c FROM lessons').get().c;
    const entities = this.db.prepare('SELECT COUNT(*) as c FROM entities').get().c;

    let archivedFiles = 0;
    try {
      const walk = (dir) => {
        for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
          if (e.isDirectory()) walk(path.join(dir, e.name));
          else archivedFiles++;
        }
      };
      walk(this.archiveDir);
    } catch {}

    return {
      facts: { total, active, hot, warm, cold },
      lessons, entities, archived: archivedFiles,
      lastGC: this.index.lastGC,
      lastReflection: this.index.lastReflection,
      backend: 'sqlite',
    };
  }

  exportJson() {
    return {
      exportedAt: this._now(),
      backend: 'sqlite',
      facts: this.db.prepare('SELECT * FROM facts').all().map(r => ({ ...r, tags: JSON.parse(r.tags || '[]') })),
      lessons: this.db.prepare('SELECT * FROM lessons').all(),
      entities: this.db.prepare('SELECT * FROM entities').all().map(r => ({
        ...r, attributes: JSON.parse(r.attributes || '{}'), factIds: JSON.parse(r.factIds || '[]'),
      })),
    };
  }

  /**
   * Migrate data from JSON store to SQLite (one-time import).
   */
  migrateFromJson(jsonStore) {
    const tx = this.db.transaction(() => {
      for (const f of jsonStore.facts) {
        try {
          this.db.prepare(`
            INSERT OR IGNORE INTO facts (id, content, tags, source, confidence, createdAt, lastAccessed, accessCount, expiresAt, supersededBy)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `).run(f.id, f.content, JSON.stringify(f.tags), f.source, f.confidence, f.createdAt, f.lastAccessed, f.accessCount, f.expiresAt, f.supersededBy);
          try { this.db.prepare('INSERT OR IGNORE INTO facts_fts (id, content, tags) VALUES (?, ?, ?)').run(f.id, f.content, f.tags.join(' ')); } catch {}
        } catch {}
      }
      for (const l of jsonStore.lessons) {
        try {
          this.db.prepare(`
            INSERT OR IGNORE INTO lessons (id, action, context, outcome, insight, createdAt, appliedCount)
            VALUES (?, ?, ?, ?, ?, ?, ?)
          `).run(l.id, l.action, l.context, l.outcome, l.insight, l.createdAt, l.appliedCount);
          try { this.db.prepare('INSERT OR IGNORE INTO lessons_fts (id, action, context, insight) VALUES (?, ?, ?, ?)').run(l.id, l.action, l.context, l.insight); } catch {}
        } catch {}
      }
      for (const e of jsonStore.entities) {
        try {
          this.db.prepare(`
            INSERT OR IGNORE INTO entities (id, name, entityType, attributes, firstSeen, lastUpdated, factIds)
            VALUES (?, ?, ?, ?, ?, ?, ?)
          `).run(e.id, e.name, e.entityType, JSON.stringify(e.attributes), e.firstSeen, e.lastUpdated, JSON.stringify(e.factIds));
        } catch {}
      }
    });
    tx();
  }
}

module.exports = { SqliteStore, isAvailable };
