# Nexo Plugin Metadata Analysis

The provided file `nexo-1.16.1.jar` was identified as a Minecraft server plugin built for the Paper/Folia platform. 

## General Information
- **Plugin Name:** Nexo
- **Version:** 1.16.1
- **Authors:** boy0000
- **Main Class:** `com.nexomc.nexo.NexoPlugin`
- **API Version:** 1.21
- **Platform Compatibility:** Paper, Folia (Supported)

## Build Metadata
- **Built By:** sivert
- **Build Tool:** Gradle 9.0.0
- **JDK Version:** 21.0.8 (JetBrains s.r.o.)
- **Multi-Release:** Yes

## Dependencies
The plugin interacts with or requires the following plugins (if present):
- **Core Mechanics:** WorldEdit, WorldGuard, PlaceholderAPI, ModelEngine
- **Protection/Claims:** BentoBox, Lands, Towny, GriefPrevention, HuskClaims, HuskTowns, PlotSquared, BlockLocker
- **Other:** AxiomPaper, Factions, MMOItems, MythicCrucible, MythicMobs, Spartan, TAB, Vulcan

## Identified Permissions (Partial)
Based on string analysis of the command handler:
- `nexo.command` - General command access
- `nexo.command.resetcmd` - Permission to reset commands/config

## Technical Summary
The JAR contains NMS (Native Minecraft Server) handlers for multiple versions of Minecraft 1.21 (v1_21_R1 through v1_21_R4), indicating broad compatibility with recent Minecraft updates. It is heavily integrated with the Paper/Folia ecosystem.

---
*Analysis performed using command-line tools (unzip, grep, strings).*
