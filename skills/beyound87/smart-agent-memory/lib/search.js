/**
 * Lightweight full-text search for Markdown files.
 * No external dependencies. Scores by TF + recency.
 */

'use strict';
const fs = require('fs');
const path = require('path');

/**
 * Search all .md files in a directory (recursive) for a query.
 * @param {string} dir - Directory to search
 * @param {string} query - Space-separated search terms
 * @param {object} opts - { limit, excludeDirs }
 * @returns {Array<{file, line, content, score}>}
 */
function searchFiles(dir, query, { limit = 20, excludeDirs = ['.archive', '.data'] } = {}) {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (terms.length === 0) return [];

  const results = [];

  function walk(d) {
    let entries;
    try { entries = fs.readdirSync(d, { withFileTypes: true }); } catch { return; }

    for (const entry of entries) {
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) {
        if (!excludeDirs.includes(entry.name)) walk(full);
      } else if (entry.name.endsWith('.md')) {
        try {
          const content = fs.readFileSync(full, 'utf8');
          const lines = content.split('\n');
          let fileScore = 0;
          const matchedLines = [];

          for (let i = 0; i < lines.length; i++) {
            const lower = lines[i].toLowerCase();
            let lineScore = 0;
            for (const t of terms) {
              if (lower.includes(t)) lineScore += 10;
            }
            if (lineScore > 0) {
              fileScore += lineScore;
              matchedLines.push({ line: i + 1, content: lines[i].trim() });
            }
          }

          if (fileScore > 0) {
            // Recency bonus
            try {
              const stat = fs.statSync(full);
              const ageDays = (Date.now() - stat.mtime.getTime()) / 86400000;
              if (ageDays < 7) fileScore += 15;
              else if (ageDays < 30) fileScore += 5;
            } catch {}

            results.push({
              file: path.relative(dir, full),
              score: fileScore,
              matches: matchedLines.slice(0, 5), // top 5 matching lines
            });
          }
        } catch {}
      }
    }
  }

  walk(dir);
  results.sort((a, b) => b.score - a.score);
  return results.slice(0, limit);
}

module.exports = { searchFiles };
