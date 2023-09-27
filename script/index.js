import { Canvas, loadImage } from "skia-canvas"
import path from "node:path"
import fs from "node:fs"

if (fs.existsSync("../assets")) fs.rmSync("../assets", { recursive: true })

fs.mkdirSync("../assets/minecraft/textures", { recursive: true })

const source = "../../1.20.2"

const getFiles = async function*(dir) {
  const dirents = await fs.promises.readdir(dir, { withFileTypes: true })
  for (const dirent of dirents) {
    const res = path.resolve(dir, dirent.name)
    if (dirent.isDirectory()) {
      yield* getFiles(res)
    } else {
      yield res
    }
  }
}

async function generate(folder) {
  const dir = path.join(source, "assets/minecraft/textures", folder)
  for await (const f of getFiles(dir)) if (f.endsWith(".png")) {
    const outDir = path.dirname(path.join("../assets", f.split("assets")[1]))
    fs.mkdirSync(outDir, { recursive: true })
    const file = path.basename(f)
    const img = await loadImage(f)
    const w = img.width
    let h = img.height
    let mcmeta = { animation: {} }
    if (fs.existsSync(f + ".mcmeta")) {
      mcmeta = JSON.parse(fs.readFileSync(f + ".mcmeta"))
      if (mcmeta.animation) {
        mcmeta.animation = {}
        h = w
      } else {
        if (img.width !== img.height) {
          mcmeta.animation = { height: img.height }
        }
      }
    } else if (img.width !== img.height) {
      mcmeta.animation = { height: img.height }
    }
    fs.writeFileSync(path.join(outDir, file) + ".mcmeta", JSON.stringify(mcmeta))
    const canvas = new Canvas(w, h * w)
    const ctx = canvas.getContext("2d")
    for (let x = 0; x < w; x++) {
      ctx.drawImage(img, 0, 0, w, h, x, x * h, w, h)
      ctx.drawImage(img, 0, 0, w, h, x - w, x * h, w, h)
    }
    canvas.saveAs(path.join(outDir, file))
  }
}

await generate("block")
await generate("item")
await generate("particle")
await generate("gui/sprites")
await generate("painting")
await generate("entity/chest")