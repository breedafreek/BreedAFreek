// Draws each Freek exported by harness.luau to a PNG (front and back three-quarter views),
// using three.js in headless Chromium. Usage: node render.mjs <freeks.json> <outDir>

import { readFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const [, , inputPath, outDir] = process.argv;
const freeks = JSON.parse(readFileSync(inputPath, "utf8"));
mkdirSync(outDir, { recursive: true });

const RARITY_COLORS = {
  Common: "#c8c8c8", Uncommon: "#5adc5a", Rare: "#4696ff", Legendary: "#ffb428",
  Mystic: "#be5aff", Ultra: "#ff3c64", Secret: "#ffffff",
};

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || "/opt/pw-browsers/chromium",
  args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 1200, height: 760 }, deviceScaleFactor: 1 });
await page.setContent(`<!doctype html><html><head><style>
  body { margin: 0; background: #1b1230; font-family: Arial Black, Arial, sans-serif; }
  #card { width: 1200px; height: 760px; position: relative; overflow: hidden; }
  canvas { display: block; }
  .title { position: absolute; left: 0; right: 0; top: 18px; text-align: center; color: white;
           font-size: 44px; text-shadow: 0 3px 0 #000; }
  .sub { position: absolute; left: 0; right: 0; top: 74px; text-align: center; font-size: 24px;
         text-shadow: 0 2px 0 #000; }
  .view { position: absolute; bottom: 64px; width: 600px; text-align: center; color: #cbbfe6; font-size: 18px; }
  .fx { position: absolute; left: 0; right: 0; bottom: 22px; text-align: center; color: #ffe27a; font-size: 20px;
        text-shadow: 0 2px 0 #000; }
</style></head><body><div id="card"><canvas id="c" width="1200" height="760"></canvas>
  <div class="title" id="title"></div><div class="sub" id="sub"></div>
  <div class="view" style="left:0">Front</div><div class="view" style="left:600px">Back</div>
  <div class="fx" id="fx"></div></div></body></html>`);
await page.addScriptTag({ path: join(dirname(fileURLToPath(import.meta.url)), "node_modules/three/build/three.min.js") });

for (const freek of freeks) {
  await page.evaluate(({ freek, rarityColor }) => {
    const THREE = window.THREE;
    const canvas = document.getElementById("c");
    const renderer = window.__renderer || new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: true });
    window.__renderer = renderer;
    renderer.setSize(1200, 760, false);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.outputEncoding = THREE.sRGBEncoding;
    renderer.setScissorTest(true);

    const scene = new THREE.Scene();
    scene.add(new THREE.HemisphereLight(0xffffff, 0x6a5a80, 0.75));
    const sun = new THREE.DirectionalLight(0xffffff, 0.9);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    scene.add(sun);
    scene.add(sun.target);

    const group = new THREE.Group();
    scene.add(group);
    const effectNames = new Set();
    const pendingEffects = [];

    const wedgeGeometry = () => {
      // Roblox WedgePart: full height at the back (+Z), sloping down to the front (-Z).
      const shape = new THREE.Shape();
      shape.moveTo(-0.5, -0.5); // (z, y)
      shape.lineTo(0.5, -0.5);
      shape.lineTo(0.5, 0.5);
      shape.closePath();
      const geo = new THREE.ExtrudeGeometry(shape, { depth: 1, bevelEnabled: false });
      geo.translate(0, 0, -0.5);
      geo.rotateY(-Math.PI / 2); // extrude along X; shape x becomes Z
      return geo;
    };

    for (const p of freek.parts) {
      const [sx, sy, sz] = p.size;
      let geometry;
      let scale = [sx, sy, sz];
      if (p.class === "WedgePart") {
        geometry = wedgeGeometry();
      } else if (p.shape === "Ball") {
        geometry = new THREE.SphereGeometry(0.5, 48, 32);
        const d = Math.min(sx, sy, sz);
        scale = [d, d, d];
      } else if (p.shape === "Cylinder") {
        geometry = new THREE.CylinderGeometry(0.5, 0.5, 1, 40);
        geometry.rotateZ(Math.PI / 2);
        const d = Math.min(sy, sz);
        scale = [sx, d, d];
      } else {
        geometry = new THREE.BoxGeometry(1, 1, 1);
      }

      const color = new THREE.Color().setRGB(...p.color).convertSRGBToLinear();
      if (p.rainbow) color.setHSL((p.position[0] * 0.15 + p.position[1] * 0.1 + 0.8) % 1, 0.8, 0.55);
      const opacity = 1 - (p.transparency || 0);
      let material;
      if (p.material === "Neon") {
        material = new THREE.MeshBasicMaterial({ color: color.clone().multiplyScalar(1.4) });
      } else {
        const metal = p.material === "Foil" || p.material === "Metal" || p.material === "DiamondPlate";
        material = new THREE.MeshStandardMaterial({
          color,
          roughness: metal ? 0.25 : p.material === "SmoothPlastic" ? 0.45 : 0.7,
          metalness: metal ? 0.75 : 0,
        });
      }
      if (p.material === "Glass") material.opacity = Math.min(opacity, 0.45);
      else material.opacity = opacity;
      material.transparent = material.opacity < 1;

      const mesh = new THREE.Mesh(geometry, material);
      const r = p.rotation;
      const m = new THREE.Matrix4().set(
        r[0], r[1], r[2], p.position[0],
        r[3], r[4], r[5], p.position[1],
        r[6], r[7], r[8], p.position[2],
        0, 0, 0, 1);
      m.multiply(new THREE.Matrix4().makeScale(...scale));
      mesh.matrixAutoUpdate = false;
      mesh.matrix.copy(m);
      mesh.castShadow = opacity > 0.5;
      mesh.receiveShadow = true;
      group.add(mesh);

      for (const fx of p.effects) pendingEffects.push({ fx, part: p, sx, sy, sz });
    }

    const box = new THREE.Box3().setFromObject(group);
    const sphere = box.getBoundingSphere(new THREE.Sphere());
    const ground = new THREE.Mesh(
      new THREE.CircleGeometry(sphere.radius * 1.3, 64),
      new THREE.MeshStandardMaterial({ color: 0x4f8f43, roughness: 1 }));
    ground.rotation.x = -Math.PI / 2;
    ground.position.y = Math.min(0, box.min.y) - 0.01;
    ground.receiveShadow = true;
    scene.add(ground);

    sun.position.set(sphere.center.x - sphere.radius * 2, sphere.center.y + sphere.radius * 4, sphere.center.z - sphere.radius * 3);
    sun.target.position.copy(sphere.center);
    const sc = sun.shadow.camera;
    sc.left = sc.bottom = -sphere.radius * 2;
    sc.right = sc.top = sphere.radius * 2;
    sc.near = 0.1;
    sc.far = sphere.radius * 12;
    sc.updateProjectionMatrix();


    // Simple stand-ins for particle effects, drawn after framing so they don't change the zoom.
    for (const { fx, part: p, sx, sy, sz } of pendingEffects) {
      const kind = fx.ClassName;
      if (!["Sparkles", "Fire", "Smoke", "ParticleEmitter", "PointLight", "Trail", "Beam"].includes(kind)) continue;
      effectNames.add(kind === "PointLight" ? "Glow" : kind);
      const base = new THREE.Vector3(...p.position);
      const radius = Math.max(sx, sy, sz) * 0.5;
      const pick = (v) => (Array.isArray(v) && Array.isArray(v[0]) ? v[0] : v);
      const c = new THREE.Color().setRGB(...pick(fx.SparkleColor || fx.Color || [1, 0.9, 0.4]));
      if (kind === "PointLight") {
        const light = new THREE.PointLight(c, 1.6, (fx.Range || 10) * 1.5);
        light.position.copy(base);
        scene.add(light);
        const halo = new THREE.Mesh(new THREE.SphereGeometry(radius * 1.35, 32, 16),
          new THREE.MeshBasicMaterial({ color: c, transparent: true, opacity: 0.12, depthWrite: false }));
        halo.position.copy(base);
        scene.add(halo);
        continue;
      }
      if (kind === "Fire") {
        const c2 = new THREE.Color().setRGB(...pick(fx.SecondaryColor || [1, 0.85, 0.3]));
        for (let i = 0; i < 14; i++) {
          const a = (i / 14) * Math.PI * 2;
          const r = radius * (0.2 + Math.random() * 0.6);
          const h = radius * (0.8 + Math.random() * 1.2);
          const flame = new THREE.Mesh(new THREE.ConeGeometry(radius * 0.22, h, 12),
            new THREE.MeshBasicMaterial({ color: c.clone().lerp(c2, Math.random()), transparent: true, opacity: 0.8, depthWrite: false }));
          flame.position.set(base.x + Math.cos(a) * r, base.y + radius * 0.7 + h / 2, base.z + Math.sin(a) * r);
          scene.add(flame);
        }
        continue;
      }
      for (let i = 0; i < 26; i++) {
        const dir = new THREE.Vector3(Math.random() - 0.5, Math.random() * 0.9 - 0.2, Math.random() - 0.5).normalize();
        const pos = base.clone().add(dir.multiplyScalar(radius * (1.1 + Math.random() * 0.6)));
        if (kind === "Smoke") pos.y += Math.random() * radius * 1.5;
        const dot = new THREE.Mesh(new THREE.SphereGeometry(0.5, 12, 8),
          new THREE.MeshBasicMaterial({ color: kind === "Smoke" ? c.clone().lerp(new THREE.Color(0.6, 0.6, 0.6), 0.5) : c,
            transparent: true, opacity: kind === "Smoke" ? 0.35 : 0.9, depthWrite: false }));
        dot.position.copy(pos);
        dot.scale.setScalar(radius * (kind === "Smoke" ? 0.6 : 0.16));
        scene.add(dot);
      }
    }

    const top = new THREE.Color(rarityColor).lerp(new THREE.Color(0x1b1230), 0.55);
    scene.background = null;
    renderer.setClearColor(0x000000, 0);
    canvas.style.background = `radial-gradient(circle at 50% 40%, #${top.getHexString()}, #1b1230 75%)`;

    const views = [
      { x: 0, dir: new THREE.Vector3(-0.5, 0.35, -1) }, // front: Roblox faces -Z
      { x: 600, dir: new THREE.Vector3(0.6, 0.35, 1) },
    ];
    for (const view of views) {
      const camera = new THREE.PerspectiveCamera(30, 600 / 760, 0.1, 1000);
      const distance = sphere.radius / Math.sin((30 * Math.PI) / 360) * 1.25;
      camera.position.copy(sphere.center).add(view.dir.normalize().multiplyScalar(distance));
      camera.lookAt(sphere.center.clone().add(new THREE.Vector3(0, -sphere.radius * 0.1, 0)));
      renderer.setViewport(view.x, 30, 600, 700);
      renderer.setScissor(view.x, 0, 600, 760);
      renderer.clear();
      renderer.render(scene, camera);
    }

    document.getElementById("title").textContent = freek.name + (freek.mutation ? ` (${freek.mutation})` : "");
    const sub = document.getElementById("sub");
    sub.textContent = freek.rarity + (freek.season ? ` · ${freek.season}` : "");
    sub.style.color = rarityColor;
    document.getElementById("fx").textContent = effectNames.size ? "Effects: " + [...effectNames].join(", ") : "";
  }, { freek, rarityColor: RARITY_COLORS[freek.rarity] || "#ffffff" });

  const file = join(outDir, `${freek.id}${freek.mutation ? "-" + freek.mutation : ""}.png`);
  await page.locator("#card").screenshot({ path: file });
  console.log(file);
}

await browser.close();
