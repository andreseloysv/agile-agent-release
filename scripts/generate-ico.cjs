// generate-ico.cjs - Zero-dependency PNG → ICO converter using only Node.js built-ins
// Works by reading the PNG as-is and packaging it directly as a PNG-encoded ICO (Vista+)

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const pngPath = path.join(__dirname, '..', 'scripts', 'icon.png');
const icoPath = path.join(__dirname, '..', 'scripts', 'icon.ico');

// Modern ICO format supports PNG-compressed images directly (Windows Vista+)
// This method just wraps the PNG binary inside an ICO container
function buildIcoFromPng(pngBuffer) {
  const numImages = 1;
  const ICO_HEADER_SIZE = 6;
  const ICONDIRENTRY_SIZE = 16;
  const dirOffset = ICO_HEADER_SIZE + (ICONDIRENTRY_SIZE * numImages);

  const header = Buffer.alloc(ICO_HEADER_SIZE);
  header.writeUInt16LE(0, 0);        // reserved
  header.writeUInt16LE(1, 2);        // type: 1 = ICO
  header.writeUInt16LE(numImages, 4); // count

  const dirEntry = Buffer.alloc(ICONDIRENTRY_SIZE);
  dirEntry.writeUInt8(0, 0);    // width: 0 = 256
  dirEntry.writeUInt8(0, 1);    // height: 0 = 256
  dirEntry.writeUInt8(0, 2);    // color count
  dirEntry.writeUInt8(0, 3);    // reserved
  dirEntry.writeUInt16LE(1, 4); // planes
  dirEntry.writeUInt16LE(32, 6); // bit count
  dirEntry.writeUInt32LE(pngBuffer.length, 8);  // size of image data
  dirEntry.writeUInt32LE(dirOffset, 12);         // offset to image data

  return Buffer.concat([header, dirEntry, pngBuffer]);
}

const pngBuffer = fs.readFileSync(pngPath);
const icoBuf = buildIcoFromPng(pngBuffer);
fs.writeFileSync(icoPath, icoBuf);
console.log(`icon.ico written (${icoBuf.length} bytes) with embedded PNG`);
