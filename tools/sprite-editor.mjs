#!/usr/bin/env node
import { execFile } from "node:child_process";
import fs from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(TOOL_DIR, "..");
const GAME_ASM = path.join(ROOT_DIR, "src", "game.asm");
const PAGE_FILE = path.join(TOOL_DIR, "sprite-editor.html");
const BUILD_SCRIPT = path.join(TOOL_DIR, "build.sh");
const DEFAULT_PORT = 5177;

const SPRITES = [
  { id: "enemy-1-left", name: "Enemy 1 Left", labels: ["CellEnemy1Left"] },
  { id: "enemy-1-right", name: "Enemy 1 Right", labels: ["CellEnemy1Right"] },
  { id: "enemy-2-left", name: "Enemy 2 Left", labels: ["CellEnemy2Left"] },
  { id: "enemy-2-right", name: "Enemy 2 Right", labels: ["CellEnemy2Right"] },
  { id: "bomb", name: "Bomb", labels: ["CellBombTopLeft", "CellBombTopRight", "CellBombBottomLeft", "CellBombBottomRight"] },
  { id: "bonus-bomb", name: "Bonus Bomb", labels: ["CellLitBombTopLeft", "CellLitBombTopRight", "CellLitBombBottomLeft", "CellLitBombBottomRight"] },
  { id: "score-200", name: "Score 200", labels: ["CellScore200TopLeft", "CellScore200TopRight", "CellScore200BottomLeft", "CellScore200BottomRight"] },
  { id: "bonus-item", name: "Bonus Item", labels: ["CellBonusItem"] },
  { id: "energy-item", name: "Energy Item", labels: ["CellEnergyItem"] },
  { id: "player-up", name: "Player Up", labels: ["CellPlayerUp"] },
  { id: "player-down", name: "Player Down", labels: ["CellPlayerDown"] },
  { id: "player-up-left", name: "Player Up Left", labels: ["CellPlayerUpLeft"] },
  { id: "player-up-right", name: "Player Up Right", labels: ["CellPlayerUpRight"] },
  { id: "player-down-left", name: "Player Down Left", labels: ["CellPlayerDownLeft"] },
  { id: "player-down-right", name: "Player Down Right", labels: ["CellPlayerDownRight"] },
  { id: "player-walk-right", name: "Player Walk Right", labels: ["CellPlayerWalkRight"] },
  { id: "player-walk-left", name: "Player Walk Left", labels: ["CellPlayerWalkLeft"] },
  { id: "enemy-1-spawn-a", name: "Enemy 1 Spawn A", labels: ["CellEnemy1SpawnA"] },
  { id: "enemy-1-spawn-b", name: "Enemy 1 Spawn B", labels: ["CellEnemy1SpawnB"] },
  { id: "enemy-1-phase-2-left", name: "Enemy 1 Phase 2 Left", labels: ["CellEnemy1Phase2Left"] },
  { id: "enemy-1-phase-2-right", name: "Enemy 1 Phase 2 Right", labels: ["CellEnemy1Phase2Right"] },
  { id: "enemy-1-phase-3", name: "Enemy 1 Phase 3", labels: ["CellEnemy1Phase3"] },
  { id: "power", name: "Power", labels: ["CellPower"] },
  { id: "enemy-frozen", name: "Frozen Enemy", labels: ["CellEnemyFrozen"] },
];

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function findSpriteDef(id) {
  return SPRITES.find((sprite) => sprite.id === id);
}

function labelBlock(source, label) {
  const pattern = new RegExp(`^${escapeRegExp(label)}:\\n([\\s\\S]*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\\z)`, "m");
  const match = source.match(pattern);
  if (!match) {
    throw new Error(`Missing sprite label: ${label}`);
  }
  return match[1];
}

function readLabelRows(source, label, expectedCount) {
  const rows = [...labelBlock(source, label).matchAll(/^\s*fcb\s+%([01]{8})\s*$/gm)].map((match) => parseInt(match[1], 2));
  if (rows.length !== expectedCount) {
    throw new Error(`${label} has ${rows.length} bitmap rows; expected ${expectedCount}`);
  }
  return rows;
}

function readSprite(source, sprite) {
  if (sprite.labels.length === 1) {
    return readLabelRows(source, sprite.labels[0], 32);
  }

  return sprite.labels.flatMap((label) => readLabelRows(source, label, 8));
}

function spritePayload(source, sprite) {
  return {
    id: sprite.id,
    name: sprite.name,
    labels: sprite.labels,
    rows: readSprite(source, sprite),
  };
}

function formatRows(rows, groupSize) {
  const lines = [];
  rows.forEach((row, index) => {
    if (index > 0 && groupSize > 0 && index % groupSize === 0) {
      lines.push("");
    }
    lines.push(`        fcb     %${row.toString(2).padStart(8, "0")}`);
  });
  return lines.join("\n");
}

function replaceLabelRows(source, label, rows, groupSize) {
  const pattern = new RegExp(`^${escapeRegExp(label)}:\\n[\\s\\S]*?(?=^[A-Za-z_][A-Za-z0-9_]*:|\\z)`, "m");
  let replaced = false;
  const nextSource = source.replace(pattern, () => {
    replaced = true;
    return `${label}:\n${formatRows(rows, groupSize)}\n\n`;
  });

  if (!replaced) {
    throw new Error(`Missing sprite label: ${label}`);
  }

  return nextSource;
}

function validateRows(rows) {
  if (!Array.isArray(rows) || rows.length !== 32) {
    throw new Error("A 2x2 sprite must contain exactly 32 bitmap rows");
  }

  rows.forEach((row, index) => {
    if (!Number.isInteger(row) || row < 0 || row > 255) {
      throw new Error(`Invalid bitmap row at index ${index}`);
    }
  });
}

function writeSprite(source, sprite, rows) {
  validateRows(rows);

  if (sprite.labels.length === 1) {
    return replaceLabelRows(source, sprite.labels[0], rows, 8);
  }

  let nextSource = source;
  sprite.labels.forEach((label, index) => {
    const start = index * 8;
    nextSource = replaceLabelRows(nextSource, label, rows.slice(start, start + 8), 0);
  });
  return nextSource;
}

function runBuild() {
  return new Promise((resolve) => {
    execFile(BUILD_SCRIPT, { cwd: ROOT_DIR }, (error, stdout, stderr) => {
      resolve({
        ok: !error,
        stdout,
        stderr,
        code: error?.code ?? 0,
      });
    });
  });
}

async function readRequestJson(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}");
}

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  response.end(JSON.stringify(payload));
}

function sendError(response, statusCode, error) {
  sendJson(response, statusCode, { error: error instanceof Error ? error.message : String(error) });
}

async function handleApi(request, response, url) {
  if (request.method === "GET" && url.pathname === "/api/sprites") {
    const source = await fs.readFile(GAME_ASM, "utf8");
    sendJson(response, 200, { sprites: SPRITES.map((sprite) => spritePayload(source, sprite)) });
    return;
  }

  const saveMatch = url.pathname.match(/^\/api\/sprites\/([^/]+)$/);
  if (request.method === "POST" && saveMatch) {
    const id = decodeURIComponent(saveMatch[1]);
    const sprite = findSpriteDef(id);
    if (!sprite) {
      sendError(response, 404, `Unknown sprite: ${id}`);
      return;
    }

    const body = await readRequestJson(request);
    const currentSource = await fs.readFile(GAME_ASM, "utf8");
    const nextSource = writeSprite(currentSource, sprite, body.rows);
    await fs.writeFile(GAME_ASM, nextSource, "utf8");
    const build = await runBuild();
    const savedSource = await fs.readFile(GAME_ASM, "utf8");
    sendJson(response, 200, {
      sprite: spritePayload(savedSource, sprite),
      build,
    });
    return;
  }

  sendError(response, 404, "Unknown API route");
}

async function createServer() {
  return http.createServer(async (request, response) => {
    try {
      const url = new URL(request.url ?? "/", "http://127.0.0.1");
      if (url.pathname.startsWith("/api/")) {
        await handleApi(request, response, url);
        return;
      }

      if (request.method === "GET" && (url.pathname === "/" || url.pathname === "/sprite-editor.html")) {
        const page = await fs.readFile(PAGE_FILE, "utf8");
        response.writeHead(200, {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
        });
        response.end(page);
        return;
      }

      response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      response.end("Not found");
    } catch (error) {
      sendError(response, 500, error);
    }
  });
}

async function listen(startPort) {
  let port = startPort;
  while (port < startPort + 40) {
    const server = await createServer();
    try {
      await new Promise((resolve, reject) => {
        server.once("error", reject);
        server.listen(port, "127.0.0.1", resolve);
      });
      return { server, port };
    } catch (error) {
      server.close();
      if (error.code !== "EADDRINUSE") {
        throw error;
      }
      port += 1;
    }
  }

  throw new Error(`No free port found from ${startPort} to ${port - 1}`);
}

const requestedPort = Number.parseInt(process.argv[2] ?? process.env.PORT ?? `${DEFAULT_PORT}`, 10);
const { port } = await listen(Number.isFinite(requestedPort) ? requestedPort : DEFAULT_PORT);

console.log(`Sprite editor running at http://127.0.0.1:${port}/`);
console.log("Press Ctrl-C to stop.");
