/**
 * Smart Agent Memory — Core Store Engine
 * Dual-layer storage: Markdown (human-readable, QMD-searchable) + JSON (structured, fast lookup)
 *
 * Zero dependencies beyond Node.js.
 */

'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class MemoryStore {
  /**
   * @param {string} memoryDir - Path to memory/ directory (usually ~/.openclaw/workspace/memory)
   */
  constructor(memoryDir) {
    this.memoryDir = memoryDir;
    this.dataDir = path.join(memoryDir, '.data');
    this.archiveDir = path.join(memoryDir, '.archive');
    this.indexFile = path.join(memoryDir, '.index.json');

    // Ensure dirs exist
    for (const d of [this.memoryDir, this.dataDir, this.archiveDir,
      path.join(memoryDir, 'lessons'), path.join(memoryDir, 'decisions'),
      path.join(memoryDir, 'people'), path.join(memoryDir, 'reflections')]) {
      fs.mkdirSync(d, { recursive: true });
    }

    // Load or init structured data
    this.facts = this._loadJson('facts.json', []);
    this.lessons = this._loadJson('lessons.json', []);
    this.entities = this._loadJson('entities.json', []);
    this.index = this._loadIndex();
  }

  // ── ID Generation ──────────────────────────────────────────────────────
  _id() {
    return crypto.randomBytes(6).toString('hex');
  }

  _now() {
    return new Date().toISOString();
  }

  // ── JSON Persistence ───────────────────────────────────────────────────
  _loadJson(filename, fallback) {
    const p = path.join(this.dataDir, filename);
    try {
      return JSON.parse(fs.readFileSync(p, 'utf8'));
    } catch {
      return fallback;
    }
  }

  _saveJson(filename, data) {
    const p = path.join(this.dataDir, filename);
    fs.writeFileSync(p, JSON.stringify(data, null, 2));
  }

  _saveFacts() { this._saveJson('facts.json', this.facts); }
  _saveLessons() { this._saveJson('lessons.json', this.lessons); }
  _saveEntities() { this._saveJson('entities.json', this.entities); }

  // ── Index (temperature + stats) ────────────────────────────────────────
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

  // ══════════════════════════════════════════════════════════════════════
  // FACTS
  // ══════════════════════════════════════════════════════════════════════

  /**
   * Remember a fact. Writes to both JSON store and a Markdown daily log.
   */
  remember(content, { tags = [], source = 'conversation', confidence = 1.0, expiresInDays = null } = {}) {
    const id = this._id();
    const now = this._now();
    const fact = {
      id, content, tags, source, confidence,
      createdAt: now, lastAccessed: now, accessCount: 1,
      expiresAt: expiresInDays ? new Date(Date.now() + expiresInDays * 86400000).toISOString() : null,
      supersededBy: null,
    };
    this.facts.push(fact);
    this._saveFacts();

    // Also append to today's daily log (Markdown layer)
    this._appendDailyLog(`- **[${id}]** ${content}${tags.length ? ' `' + tags.join('`, `') + '`' : ''}`);

    return fact;
  }

  /**
   * Search facts by keyword (simple but effective full-text search).
   */
  recall(query, { limit = 10, tags = null, minConfidence = 0 } = {}) {
    const now = this._now();
    const terms = query.toLowerCase().split(/\s+/).filter(Boolean);

    let results = this.facts.filter(f => {
      if (f.supersededBy) return false;
      if (f.expiresAt && f.expiresAt < now) return false;
      if (f.confidence < minConfidence) return false;
      if (tags && !tags.every(t => f.tags.includes(t))) return false;
      const haystack = (f.content + ' ' + f.tags.join(' ')).toLowerCase();
      return terms.every(t => haystack.includes(t));
    });

    // Score by term frequency + recency + access count
    results = results.map(f => {
      const haystack = (f.content + ' ' + f.tags.join(' ')).toLowerCase();
      let score = 0;
      for (const t of terms) {
        const idx = haystack.indexOf(t);
        if (idx !== -1) score += 10;
        // Bonus for match at start
        if (idx === 0) score += 5;
      }
      // Recency bonus (last 7 days = +5, 30 days = +2)
      const age = (Date.now() - new Date(f.createdAt).getTime()) / 86400000;
      if (age < 7) score += 5;
      else if (age < 30) score += 2;
      // Access frequency bonus
      score += Math.min(f.accessCount, 10);
      return { ...f, _score: score };
    });

    results.sort((a, b) => b._score - a._score);
    const top = results.slice(0, limit);

    // Update access stats
    for (const f of top) {
      const orig = this.facts.find(x => x.id === f.id);
      if (orig) {
        orig.lastAccessed = now;
        orig.accessCount++;
      }
    }
    if (top.length > 0) this._saveFacts();

    return top.map(({ _score, ...rest }) => rest);
  }

  getFact(id) {
    return this.facts.find(f => f.id === id) || null;
  }

  listFacts({ tags = null, limit = 50, includeSuperseded = false } = {}) {
    let results = this.facts.filter(f => {
      if (!includeSuperseded && f.supersededBy) return false;
      if (tags && !tags.some(t => f.tags.includes(t))) return false;
      return true;
    });
    return results.slice(-limit).reverse();
  }

  supersede(oldId, newContent, opts = {}) {
    const newFact = this.remember(newContent, opts);
    const old = this.facts.find(f => f.id === oldId);
    if (old) {
      old.supersededBy = newFact.id;
      this._saveFacts();
    }
    return newFact;
  }

  forget(id) {
    const idx = this.facts.findIndex(f => f.id === id);
    if (idx !== -1) {
      this.facts.splice(idx, 1);
      this._saveFacts();
      return true;
    }
    return false;
  }

  forgetStale({ days = 30, minAccessCount = 1 } = {}) {
    const cutoff = new Date(Date.now() - days * 86400000).toISOString();
    const before = this.facts.length;
    this.facts = this.facts.filter(f => {
      if (f.supersededBy) return true; // keep chain
      if (f.lastAccessed >= cutoff) return true;
      if (f.accessCount > minAccessCount) return true;
      return false;
    });
    const removed = before - this.facts.length;
    if (removed > 0) this._saveFacts();
    return removed;
  }

  // ══════════════════════════════════════════════════════════════════════
  // LESSONS
  // ══════════════════════════════════════════════════════════════════════

  learn(action, context, outcome, insight) {
    const id = this._id();
    const now = this._now();
    const lesson = { id, action, context, outcome, insight, createdAt: now, appliedCount: 0 };
    this.lessons.push(lesson);
    this._saveLessons();

    // Write Markdown file in lessons/
    const filename = `${now.slice(0, 10)}-${id}.md`;
    const md = [
      `# ${action}`,
      '', `**Context:** ${context}`,
      `**Outcome:** ${outcome}`,
      `**Insight:** ${insight}`,
      `**Date:** ${now.slice(0, 10)}`,
      `**ID:** ${id}`,
    ].join('\n');
    fs.writeFileSync(path.join(this.memoryDir, 'lessons', filename), md);

    return lesson;
  }

  getLessons({ context = null, outcome = null, limit = 10 } = {}) {
    let results = [...this.lessons];
    if (context) {
      const q = context.toLowerCase();
      results = results.filter(l => l.context.toLowerCase().includes(q));
    }
    if (outcome) {
      results = results.filter(l => l.outcome === outcome);
    }
    return results.slice(-limit).reverse();
  }

  applyLesson(id) {
    const lesson = this.lessons.find(l => l.id === id);
    if (lesson) {
      lesson.appliedCount++;
      this._saveLessons();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // ENTITIES
  // ══════════════════════════════════════════════════════════════════════

  trackEntity(name, entityType, attributes = {}) {
    const now = this._now();
    const existing = this.entities.find(e => e.name === name && e.entityType === entityType);

    if (existing) {
      Object.assign(existing.attributes, attributes);
      existing.lastUpdated = now;
      this._saveEntities();

      // Update Markdown
      this._writeEntityMd(existing);
      return existing;
    }

    const entity = {
      id: this._id(), name, entityType, attributes,
      firstSeen: now, lastUpdated: now, factIds: [],
    };
    this.entities.push(entity);
    this._saveEntities();
    this._writeEntityMd(entity);
    return entity;
  }

  getEntity(name, entityType = null) {
    return this.entities.find(e => {
      if (e.name !== name) return false;
      if (entityType && e.entityType !== entityType) return false;
      return true;
    }) || null;
  }

  listEntities(entityType = null) {
    if (entityType) return this.entities.filter(e => e.entityType === entityType);
    return [...this.entities];
  }

  linkFactToEntity(entityName, factId) {
    const entity = this.entities.find(e => e.name === entityName);
    if (entity && !entity.factIds.includes(factId)) {
      entity.factIds.push(factId);
      entity.lastUpdated = this._now();
      this._saveEntities();
    }
  }

  updateEntity(name, entityType, attributes) {
    const entity = this.entities.find(e => e.name === name && e.entityType === entityType);
    if (!entity) return null;
    Object.assign(entity.attributes, attributes);
    entity.lastUpdated = this._now();
    this._saveEntities();
    this._writeEntityMd(entity);
    return entity;
  }

  _writeEntityMd(entity) {
    const dir = entity.entityType === 'person' ? 'people' : 'decisions';
    const filename = `${entity.name.toLowerCase().replace(/\s+/g, '-')}.md`;
    const attrs = Object.entries(entity.attributes)
      .map(([k, v]) => `- **${k}:** ${v}`).join('\n');
    const md = [
      `# ${entity.name}`,
      `**Type:** ${entity.entityType}`,
      `**First seen:** ${entity.firstSeen.slice(0, 10)}`,
      `**Last updated:** ${entity.lastUpdated.slice(0, 10)}`,
      '', attrs || '_(no attributes)_',
    ].join('\n');
    try {
      fs.writeFileSync(path.join(this.memoryDir, dir, filename), md);
    } catch {}
  }

  // ══════════════════════════════════════════════════════════════════════
  // DAILY LOG (Markdown layer)
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

    const activeFacts = this.facts.filter(f => !f.supersededBy);
    const hot = activeFacts.filter(f => (now - new Date(f.createdAt).getTime()) < 7 * dayMs);
    const warm = activeFacts.filter(f => {
      const age = now - new Date(f.createdAt).getTime();
      return age >= 7 * dayMs && age < 30 * dayMs;
    });
    const cold = activeFacts.filter(f => (now - new Date(f.createdAt).getTime()) >= 30 * dayMs);

    // Count archived files
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
      facts: { total: this.facts.length, active: activeFacts.length, hot: hot.length, warm: warm.length, cold: cold.length },
      lessons: this.lessons.length,
      entities: this.entities.length,
      archived: archivedFiles,
      lastGC: this.index.lastGC,
      lastReflection: this.index.lastReflection,
    };
  }

  exportJson() {
    return {
      exportedAt: this._now(),
      facts: this.facts,
      lessons: this.lessons,
      entities: this.entities,
    };
  }
}

/**
 * Factory: auto-detect better-sqlite3 and pick the best backend.
 * Returns { store, backend } where backend is 'sqlite' or 'json'.
 */
function createStore(memoryDir) {
  const { SqliteStore, isAvailable } = require('./sqlite-store');
  if (isAvailable()) {
    try {
      const store = new SqliteStore(memoryDir);
      // Auto-migrate JSON → SQLite if JSON data exists but SQLite is empty
      const jsonFactsPath = require('path').join(memoryDir, '.data', 'facts.json');
      if (require('fs').existsSync(jsonFactsPath)) {
        const stats = store.stats();
        if (stats.facts.total === 0) {
          const jsonStore = new MemoryStore(memoryDir);
          if (jsonStore.facts.length > 0 || jsonStore.lessons.length > 0 || jsonStore.entities.length > 0) {
            store.migrateFromJson(jsonStore);
            console.log(`\x1b[32m[✓]\x1b[0m Auto-migrated ${jsonStore.facts.length} facts, ${jsonStore.lessons.length} lessons, ${jsonStore.entities.length} entities from JSON → SQLite`);
          }
        }
      }
      return { store, backend: 'sqlite' };
    } catch (e) {
      // Fallback to JSON if SQLite init fails
      console.log(`\x1b[33m[!]\x1b[0m SQLite init failed (${e.message}), falling back to JSON`);
    }
  }
  return { store: new MemoryStore(memoryDir), backend: 'json' };
}

module.exports = { MemoryStore, createStore };
