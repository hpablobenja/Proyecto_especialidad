
const fs = require("fs");

// Leer archivo lcov.info
const lcov = fs.readFileSync("lcov.info", "utf8").split("\n");

// Inicializar acumuladores por capa
const groups = {
  domain: { lf: 0, lh: 0 },
  data: { lf: 0, lh: 0 },
  presentation: { lf: 0, lh: 0 },
};

let currentFile = "";

for (const line of lcov) {
  if (line.startsWith("SF:")) {
    currentFile = line.substring(3);
  } else if (line.startsWith("LF:")) {
    const lf = parseInt(line.substring(3), 10);
    if (currentFile.includes("domain")) groups.domain.lf += lf;
    if (currentFile.includes("data")) groups.data.lf += lf;
    if (currentFile.includes("presentation")) groups.presentation.lf += lf;
  } else if (line.startsWith("LH:")) {
    const lh = parseInt(line.substring(3), 10);
    if (currentFile.includes("domain")) groups.domain.lh += lh;
    if (currentFile.includes("data")) groups.data.lh += lh;
    if (currentFile.includes("presentation")) groups.presentation.lh += lh;
  }
}

// Función para calcular cobertura
function coverage(group) {
  return group.lf > 0 ? ((group.lh / group.lf) * 100).toFixed(2) : "0.00";
}

// Mostrar resultados por capa
console.log("Cobertura por capa");
for (const [key, val] of Object.entries(groups)) {
  console.log(
    `${key}: ${val.lh} / ${val.lf} → ${coverage(val)} %`
  );
}

// Calcular cobertura global
const totalLF = groups.domain.lf + groups.data.lf + groups.presentation.lf;
const totalLH = groups.domain.lh + groups.data.lh + groups.presentation.lh;
const totalCoverage = totalLF > 0 ? ((totalLH / totalLF) * 100).toFixed(2) : "0.00";

console.log("\nCobertura global");
console.log(`${totalLH} / ${totalLF} → ${totalCoverage} %`);
