// scripts/build-plots.mjs
// Reads data/triage-data.json and regenerates assets/cost-plot.svg + assets/token-plot.svg.
// Run: node scripts/build-plots.mjs
// CI checks for drift: generated files must match the committed ones.

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");
const data = JSON.parse(readFileSync(join(root, "data", "triage-data.json"), "utf8"));
const outDir = join(root, "assets");
mkdirSync(outDir, { recursive: true });

const COL = {
  axis: "#2a313c",
  ink: "#e6e9ef",
  muted: "#9aa4b2",
  accent: "#4f9cf9",
  ok: "#3ddc97",
  stop: "#ff6b6b",
};

function esc(s) {
  return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// ---------- Cost / day line chart ----------
function buildCostPlot(d) {
  const vals = d.cost.perDay;
  const n = vals.length;
  const yMax = d.cost.yMax;
  const W = 660, H = 210;
  const xL = 50, xR = 596, yT = 20, yB = 180, plotH = yB - yT; // 160
  const x = (i) => xL + (i / (n - 1)) * (xR - xL);
  const y = (v) => yB - (v / yMax) * plotH;
  const pts = vals.map((v, i) => `${x(i).toFixed(0)},${y(v).toFixed(0)}`).join(" ");
  const baseY = y(d.cost._baseline7d);
  const spikeIdx = d.cost.spikeStartsAtIndex;
  const sx = x(spikeIdx), sy = y(vals[spikeIdx]);

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" role="img" aria-labelledby="costT costD">
  <title id="costT">Kosten pro Tag (14 Tage)</title>
  <desc id="costD">Linie der taeglichen Kosten; bleibt 9 Tage nahe Basislinie, steigt ab Tag 10 auf das 7-Fache.</desc>
  <line x1="${xL}" y1="${yB}" x2="${xR}" y2="${yB}" stroke="${COL.axis}" stroke-width="1.5"/>
  <line x1="${xL}" y1="${yT}" x2="${xL}" y2="${yB}" stroke="${COL.axis}" stroke-width="1.5"/>
  <line x1="${xL}" y1="${baseY.toFixed(0)}" x2="${xR}" y2="${baseY.toFixed(0)}" stroke="${COL.ok}" stroke-width="1.4" stroke-dasharray="5 4"/>
  <text x="${xR + 4}" y="${(baseY + 3).toFixed(0)}" fill="${COL.ok}" font-size="10" font-family="monospace">7d</text>
  <polyline points="${pts}" fill="none" stroke="${COL.accent}" stroke-width="2.4"/>
  <circle cx="${sx.toFixed(0)}" cy="${sy.toFixed(0)}" r="4" fill="${COL.stop}"/>
  <line x1="${sx.toFixed(0)}" y1="${sy.toFixed(0)}" x2="${sx.toFixed(0)}" y2="${yT + 16}" stroke="${COL.stop}" stroke-width="1" stroke-dasharray="3 3"/>
  <text x="${sx + 8}" y="${yT + 20}" fill="${COL.stop}" font-size="11" font-family="monospace">Spike ab Tag ${spikeIdx + 1}</text>
  <text x="${xL}" y="${H - 2}" fill="${COL.muted}" font-size="10" font-family="monospace" text-anchor="middle">1</text>
  <text x="${x(spikeIdx).toFixed(0)}" y="${H - 2}" fill="${COL.muted}" font-size="10" font-family="monospace" text-anchor="middle">${spikeIdx + 1}</text>
  <text x="${xR}" y="${H - 2}" fill="${COL.muted}" font-size="10" font-family="monospace" text-anchor="middle">${n}</text>
  <text x="10" y="${yB}" fill="${COL.muted}" font-size="10" font-family="monospace">0</text>
  <text x="4" y="${yT + 12}" fill="${COL.muted}" font-size="10" font-family="monospace">${yMax}</text>
  <text x="${W / 2}" y="14" fill="${COL.ink}" font-size="12" text-anchor="middle">Kosten / Tag (14 Tage)</text>
</svg>
`;
}

// ---------- Token distribution grouped bars ----------
function buildTokenPlot(d) {
  const t = d.tokens;
  const yMax = t.yMax;
  const W = 660, H = 210;
  const yT = 20, yB = 190, plotH = yB - yT; // 170
  const y = (v) => yB - (v / yMax) * plotH;
  const h = (v) => (v / yMax) * plotH;
  const barW = 30, gap = 4, step = barW + gap;
  const groups = [
    { key: "before", label: "vor Incident", col: COL.accent, vals: t.before, x0: 120 },
    { key: "after", label: "waehrend Incident", col: COL.stop, vals: t.after, x0: 400 },
  ];
  const order = ["p50", "p95", "p99"];

  let bars = "";
  for (const g of groups) {
    order.forEach((k, i) => {
      const v = g.vals[k];
      const bx = g.x0 + i * step;
      const by = y(v);
      bars += `<rect x="${bx}" y="${by.toFixed(0)}" width="${barW}" height="${h(v).toFixed(0)}" fill="${g.col}"/>\n`;
      // label above bar (move p95/p99 label up if tall)
      const ly = v > yMax * 0.4 ? by - 6 : by + 12;
      const lcol = v > yMax * 0.4 ? g.col : COL.ink;
      bars += `<text x="${bx + barW / 2}" y="${ly.toFixed(0)}" fill="${lcol}" font-size="9" text-anchor="middle">${k.toUpperCase()}</text>\n`;
    });
    const cx = g.x0 + (3 * step - gap) / 2;
    bars += `<text x="${cx}" y="${H - 2}" fill="${COL.muted}" font-size="11" text-anchor="middle" font-family="monospace">${esc(g.label)}</text>\n`;
  }

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" role="img" aria-labelledby="tokT tokD">
  <title id="tokT">Prompt-Token-Verteilung P50/P95/P99</title>
  <desc id="tokD">Gruppierte Balken: P50 bleibt gleich, aber P95 und P99 steigen waehrend des Incidents massiv an.</desc>
  <line x1="40" y1="${yB}" x2="${W - 10}" y2="${yB}" stroke="${COL.axis}" stroke-width="1.5"/>
  <line x1="40" y1="${yT}" x2="40" y2="${yB}" stroke="${COL.axis}" stroke-width="1.5"/>
${bars}
  <text x="${W / 2}" y="14" fill="${COL.ink}" font-size="12" text-anchor="middle">Prompt-Tokens / Request (P50/P95/P99)</text>
</svg>
`;
}

const costSvg = buildCostPlot(data);
const tokenSvg = buildTokenPlot(data);
writeFileSync(join(outDir, "cost-plot.svg"), costSvg, "utf8");
writeFileSync(join(outDir, "token-plot.svg"), tokenSvg, "utf8");
console.log("Generated assets/cost-plot.svg and assets/token-plot.svg from data/triage-data.json");
