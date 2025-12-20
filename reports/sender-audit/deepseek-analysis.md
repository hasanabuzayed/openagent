# Nexo Minecraft Plugin Package Extraction Analysis

## Overview
Successfully extracted and analyzed `nexo-1.16.1.jar`, a Minecraft plugin (Paper/Folia-compatible).

## Extraction Summary

### Extraction Method
- **Tool Used**: `unzip` command-line utility
- **Location**: `/root/work/mission-e033566c/output/extracted/`
- **Files Extracted**: 2133 files total
- **Decompilation**: CFR Java decompiler (`cfr-0.152.jar`) used to decompile Java class files
- **Decompiled Files**: 2146 Java source files

## Package Structure Analysis

### File Structure
```
/
├── META-INF/
│   ├── MANIFEST.MF                    # Build metadata
│   ├── maven/                        # Maven dependencies
│   ├── proguard/                     # ProGuard configuration
│   └── *.shadow.kotlin_module        # Kotlin module files
├── com/
│   ├── google/                       # Google dependencies (Gson, Error Prone)
│   └── nexomc/
│       ├── customblockdata/          # Custom block data library
│       ├── libs/                     # Libraries
│       ├── nexo/                     # Main plugin code
│       └── protectionlib/            # Protection library
├── converter.yml                     # Item converter configuration
├── cred.secret                       # Object storage credentials
├── custom_armor/
│   └── transparent.png              # Texture file
├── glyphs/
│   └── nexo_defaults/
│       └── interface.yml            # GUI interface configuration
├── items/
│   └── nexo_defaults/
│       ├── gui_icons.yml           # GUI icons
│       ├── nexo_armor.yml          # Armor items
│       ├── nexo_connectable.yml    # Connectable items
│       ├── nexo_furniture.yml      # Furniture items
│       └── nexo_tools.yml          # Tool items
├── languages.yml                    # Language translation keys
├── mechanics.yml                    # Plugin mechanics configuration
├── messages/                       # Language files
│   ├── english.yml
│   ├── french.yml
│   ├── german.yml
│   ├── czech.yml
│   ├── polish.yml
│   ├── korean.yml
│   ├── slovak.yml
│   ├── ru-RU.yml
│   ├── zh-CN.yml
│   ├── JPN_JP.yml
│   ├── turkish.yml
│   ├── pt-BR.yml
│   └── zh-TW.yml
├── META-INF/
├── mp.secret                        # Marketplace/license verification
├── paper-plugin.yml                # Paper plugin manifest
├── polymart.yml                    # Polymart marketplace configuration
├── shaders/
│   ├── gifs/                       # Animated GIF shaders
│   │   ├── nexo_gif_utils.glsl
│   │   ├── v1_21_1/
│   │   ├── v1_21_3/
│   │   └── v1_21_6/
│   └── score_tab/                  # Scoreboard tab shaders
│       ├── v1_21_1/
│       └── v1_21_6/
├── sounds.yml                      # Sound configuration
├── team/
│   └── unnamed/
│       └── creative/               # Team/creative mode files
└── token.secret                    # GitHub token for default pack
```

## Key Findings

### 1. Plugin Metadata
- **Name**: Nexo
- **Version**: 1.16.1
- **Main Class**: `com.nexomc.nexo.NexoPlugin`
- **Loader**: `com.nexomc.nexo.PaperPluginLoader`
- **Bootstrapper**: `com.nexomc.nexo.NexoBootstrap`
- **Folia Supported**: Yes (compatible with Folia server software)
- **API Version**: 1.21

### 2. Dependencies
The plugin has optional dependencies on several popular Minecraft plugins:
- AxiomPaper
- BentoBox
- BlockLocker
- Factions
- HuskClaims
- HuskTowns
- Lands
- MMOItems
- ModelEngine
- MythicCrucible
- MythicMobs
- PlaceholderAPI
- PlotSquared
- Spartan
- TAB
- Towny
- Vacan
- Vulcan
- WorldEdit
- WorldGuard

### 3. Build Information
- **Built By**: sivert
- **Build Tool**: Gradle 9.0.0
- **Build JDK**: 21.0.8 JetBrains s.r.o. 21.0.8+9-b1097.42
- **Multi-Release**: Yes (supports multiple Java versions)

### 4. Security/Secrets Found

#### **cred.secret** - Object Storage Credentials
```json
{
  "url": "https://fsn1.your-objectstorage.com",
  "bucket": "nexo-storage",
  "access": "OGW86KJE9YMELF54B6DB",
  "secret": "GC3ZjskMihXoDbNDVQ3PdITts7QbVAMuW9Lgzph6"
}
```
**Risk**: Exposed S3-compatible object storage credentials

#### **token.secret** - GitHub Access Token
```
token1: Z2l0aHViX3BhdF8xMUFPNUFBR1kwUlh0VW16OExJdHBPX1hBQWZXZTFQY
token2: m43YzI3amlTc0Y4dnNtSzNRaWZqZDNaa2ltOXA4eVVEd1lKMkxaNE9SSWtDeG16d0Qw
```
**Risk**: Exposed GitHub Personal Access Token (base64 encoded)

#### **mp.secret** - Marketplace Verification Template
Contains placeholder variables for marketplace/license verification:
- `{{USER_NAME}}`
- `{{USER}}`
- `{{USER_IDENTIFIER}}`
- `{{TIMESTAMP}}`
- `{{RESOURCE}}`
- `{{RESOURCE_VERSION}}`
- `{{NONCE}}`
- `{{MCMODELS}}`

### 5. Supported Minecraft Versions
The plugin contains NMS (Net Minecraft Server) handlers for multiple versions:
- v1_21_R1
- v1_21_R2
- v1_21_R3
- v1_21_R4
- v1_21_R6
- v1_21_R8
- v1_21_R10

### 6. Core Features Identified
Based on the decompiled code and configuration files:

1. **Custom Items System** - Extensive item creation and management
2. **Furniture System** - Custom furniture with hitboxes and interaction
3. **Custom Blocks** - Custom block types with special properties
4. **Resource Pack Management** - Server resource pack generation and delivery
5. **Compatibility Layer** - Converters for Oraxen and ItemsAdder plugins
6. **Packet Manipulation** - Network packet transformers for custom items
7. **Multi-Language Support** - Extensive translation system
8. **GUI System** - Custom inventory interfaces
9. **Sound System** - Custom sound effects
10. **Protection Integration** - WorldGuard and other protection plugin compatibility
11. **Folia Support** - Multi-threaded server compatibility

### 7. Converter System
The plugin includes converters for migrating from other item plugins:
- **Oraxen Converter**: Converts Oraxen items, resource packs, and settings
- **ItemsAdder Converter**: Converts ItemsAdder items and resource packs

### 8. Resource Pack Generation
Contains shaders and GLSL files for:
- Animated GIF support (`shaders/gifs/`)
- Scoreboard tab customization (`shaders/score_tab/`)
- Multiple Minecraft versions (1.21.1, 1.21.3, 1.21.6)

## Technical Analysis

### Architecture
- **Primary Language**: Kotlin (evident from Kotlin metadata files)
- **Build System**: Gradle
- **Dependencies**: Google Gson, FoliaLib, CustomBlockData, ProtectionLib
- **NMS Handlers**: Version-specific Net Minecraft Server implementations
- **Packet System**: Custom packet transformers for item and component serialization

### Security Concerns
1. **Exposed Credentials**: Object storage credentials and GitHub tokens in plain text
2. **License Verification**: Template-based marketplace verification system
3. **Network Manipulation**: Packet transformers could be used for malicious purposes if compromised

### Code Quality Indicators
- **ProGuard Usage**: Code is obfuscated/minified
- **Multi-Version Support**: Clean separation of NMS version handlers
- **Modular Design**: Separate managers for different systems (sound, inventory, fonts, etc.)
- **Error Handling**: Kotlin Result types and proper exception handling

## Extraction Details

### Files Extracted
- **Class Files**: 2133 `.class` files
- **Configuration Files**: 42 YAML/JSON files
- **Resource Files**: Images, shaders, language files
- **Decompiled Source**: 2146 Java files from CFR decompilation

### Decompilation Quality
- CFR successfully decompiled most classes
- Some Kotlin metadata could not be loaded (expected)
- Code is readable but shows signs of optimization/obfuscation

## Recommendations for Further Analysis

1. **Credential Rotation**: The exposed credentials should be rotated immediately
2. **Code Review**: Focus on packet transformers and network handlers for security issues
3. **Dependency Audit**: Check for vulnerabilities in third-party libraries
4. **Configuration Validation**: Review YAML configurations for injection vulnerabilities
5. **Resource Pack Verification**: Ensure shader files don't contain malicious code

## Files Created During Analysis

1. **Extracted Files**: `/root/work/mission-e033566c/output/extracted/` - Raw extracted JAR contents
2. **Decompiled Source**: `/root/work/mission-e033566c/output/decompiled/` - Java source files from CFR decompilation
3. **Original JAR**: `/root/work/mission-e033566c/nexo-1.16.1.jar` - Copy of original file

## Tools Used
1. `file` - File type identification
2. `unzip` - JAR extraction
3. `jar` - Java archive inspection
4. `tree` - Directory structure visualization
5. `CFR 0.152` - Java bytecode decompiler

## Conclusion
The Nexo plugin is a sophisticated Minecraft server plugin with extensive features for custom items, furniture, resource packs, and compatibility with other plugins. The extraction revealed both the plugin's capabilities and security concerns including exposed credentials that should be addressed.