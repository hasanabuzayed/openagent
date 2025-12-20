# Nexo Plugin Runtime and Message Passing Protocol Analysis

## 1. Runtime Environment

- **Architecture**: Kotlin + Java mixed runtime
- **Minecraft Version**: 1.21 R3 (uses `net.minecraft` classes directly)
- **Server Platform**: Paper (specific `paper-plugin.yml` config)
- **Dependencies**: Server-side plugin hooks via classpath joins (BentoBox, PlaceholderAPI, WorldEdit, etc.)

## 2. Message Passing Protocols

### 2.1 Internal Packet Handling

- **Core Class**: `NexoChannelHandler` extends `NexoCommonsHandler`
- **Packet Transformers**:
```java
// Packet-specific transformers
- ComponentTransformer
- ItemTransformer
- MerchantTransformer
```
- **Key Methods**: 
```java
@Override
public ProtocolInfo<ClientGamePacketListener> getProtocolInfo() {
    return protInfo; // Static protocol template
}
```

### 2.2 External Plugin Integration

- Uses standard Bukkit plugin messaging for dependencies
- Example dependency chain:
```yaml
# paper-plugin.yml
loader: com.nexomc.nexo.PaperPluginLoader
dependencies:
    server:
        # 15+ plugins with join-classpath=true
        # No direct network protocols - just server hooks
```

## 3. Packet Transformation Examples

### 3.1 Team Packet Manipulation

```java
// ClientboundSetPlayerTeamPacket handling
buf.writeCollection(players, (v1, v2) -> {
    // Custom transformation logic
    // Handles prefix/suffix modifications
    // Maintains nametag visibility sync
```

### 3.2 Item Component Handling

```java
// ComponentTransformer used in multiple contexts
transform(Component displayName) {
    // Custom formatting rules
    // Palette-aware text processing
}
```

## 4. Integration Points

1. **Packet Interception**:
   - Hooks into standard Minecraft channels
   - Modifies packet content in-flight
   
2. **Plugin API** (`nexo.api.*`):
   - Exposes Item/Model/ResourcePack APIs
   - Used by dependency plugins like ModelEngine
   
3. **Configuration Sync**:
   - Uses `converter.yml` for client-server config
   - Synchronizes:
     - blockstate definitions
     - equipment layers
     - sound mappings

## 5. Findings Summary

**Similarities**:
- Follows standard Minecraft packet structure
- Uses common transformer pattern (Component/Item/Merchant)
- Maintains compatibility with multiple server implementations

**Differences**:
- Implements palette-aware string handling
- Custom buffer management with `RegistryFriendlyByteBuf`
- Kotlin-based lazy loading for sound/texture packs

**Integration Highlights**:
- Deep understanding of Minecraft's ProtocolInfo system
- Custom packet handlers for specific use cases:
  - Furniture placement (IFurniturePacketManager)
  - Inventory manipulation (ClientboundSetCursorItemPacket)
  - Player info updates (ClientboundPlayerInfoUpdatePacket)

This analysis reveals Nexo's approach as:
1. Low-level packet manipulation for visual customization
2. Server-side plugin orchestration through classpath joins
3. Kotlin-powered component architecture for modern API design