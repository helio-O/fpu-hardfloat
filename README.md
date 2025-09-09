# TFG - Diseño de una Unidad de Punto Flotante en código abierto

Este repositorio contiene el código fuente y los scripts asociados al Trabajo de Fin de Grado.  
El proyecto se centra en la implementación, integración y evaluación de distintas Unidades de Punto Flotante (FPU) abiertas sobre la FPGA Xilinx Alveo U200 (`xcu200-fsgd2104-2-e`), junto con el desarrollo de un *wrapper* en SystemVerilog.

---

## 📖 Descripción

El objetivo principal es comparar arquitecturas de punto flotante de código abierto (**HardFloat**, **FPnew** y **VFloat**) en cuanto a área, latencia y frecuencia máxima.  
Se ha desarrollado dos *wrapper* propios en SystemVerilog que integran módulos de las librerías HardFloat y VFloat y gestiona las operaciones mediante una FSM personalizada.

El repositorio incluye:
- Módulos en SystemVerilog.
- Controlador FSM para ADD, SUB, MUL, DIV y SQRT.
- Bancos de prueba y casos de validación.
- Scripts de simulación y síntesis en Vivado 2020.2.
- Resultados de utilización de recursos y frecuencia máxima.

---

## 📂 Estructura

- `src/` → Código fuente propio (wrapper, controlador, utilidades).  
- `tb/` → Testbenches y ejemplos de simulación.  
- `scripts/` → TCL/Makefiles para Vivado y simulación.  
- `results/` → Reportes de síntesis y resultados experimentales.  
- `third_party/` → Dependencias externas:  
  - `hardfloat/` → HardFloat (BSD 3-Clause).  
  - `vfloat/` → VFloat (GPL).  

---

## ▶️ Uso

1. Abrir **Vivado 2020.2**.  
2. Importar los ficheros de `src/` y `third_party/`.
3. Sintetizar e implementar tras hacer los cambios pertinentes en los módulos de las bibliotecas y/o generando los IP Cores correspondientes.
4. Ejecutar los scripts en `scripts/` para obtener los reportes de área, frecuencia y potencia.    

---

## 📜 Licencias

Este repositorio contiene tanto código propio como bibliotecas externas.  

- **Memoria del TFG** → [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)  
- **Código propio que integra HardFloat** → MIT  
- **Código propio que integra VFloat** → GPLv3 (copyleft fuerte)  
- **HardFloat** → [BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause)  
- **VFloat** → [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html) 

---

## ✒️ Autor

Trabajo Fin de Grado de **Helio O**  
Universidad Complutense de Madrid — 2025
