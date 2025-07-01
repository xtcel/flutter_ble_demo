# Flutter 蓝牙 Demo 应用

这是一个使用 Flutter 开发的蓝牙应用程序演示，展示了如何使用 `flutter_blue_plus` 库实现蓝牙设备的连接、数据发送和接收功能。

## 功能特性

- 🔍 **蓝牙设备扫描**: 扫描附近的蓝牙设备
- 🔗 **设备连接**: 连接到选定的蓝牙设备
- 📤 **数据发送**: 向连接的设备发送文本数据
- 📥 **数据接收**: 实时接收来自设备的数据
- 🔌 **连接管理**: 断开蓝牙连接
- 🛡️ **权限处理**: 自动请求必要的蓝牙和位置权限

## 技术栈

- **Flutter**: 3.19+
- **flutter_blue_plus**: ^1.32.7 - 蓝牙功能库
- **permission_handler**: ^11.3.1 - 权限管理

## 权限配置

### Android 权限

应用已配置以下 Android 权限（在 `android/app/src/main/AndroidManifest.xml` 中）：

```xml
<!-- 基础蓝牙权限 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Android 12+ (API level 31+) 权限 -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
```

### iOS 权限

应用已配置以下 iOS 权限（在 `ios/Runner/Info.plist` 中）：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs access to Bluetooth to connect to nearby devices.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs access to Bluetooth to connect to nearby devices.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to scan for Bluetooth devices.</string>
```

## 安装和运行

1. **克隆项目**（如果适用）或确保你在项目目录中

2. **安装依赖**:
   ```bash
   flutter pub get
   ```

3. **运行应用**:
   ```bash
   flutter run
   ```

## 使用说明

1. **启动应用**: 应用启动后会自动请求必要的权限

2. **扫描设备**: 点击"扫描设备"按钮开始搜索附近的蓝牙设备

3. **连接设备**: 在设备列表中点击"连接"按钮连接到目标设备

4. **发送数据**: 连接成功后，在输入框中输入消息并点击"发送"按钮

5. **接收数据**: 应用会实时显示从连接设备接收到的数据

6. **断开连接**: 点击"断开连接"按钮结束蓝牙连接

## 注意事项

- 确保设备的蓝牙功能已开启
- 在 Android 设备上，需要授予位置权限才能扫描蓝牙设备
- 应用会自动寻找具有写入和通知功能的蓝牙特征值
- 数据传输使用 UTF-8 编码

## 故障排除

### 常见问题

1. **无法扫描到设备**:
   - 确保蓝牙已开启
   - 检查权限是否已授予
   - 确保目标设备处于可发现状态

2. **连接失败**:
   - 确保设备支持连接
   - 检查设备是否已被其他应用连接
   - 重启蓝牙或重新扫描

3. **无法发送/接收数据**:
   - 确保设备支持所需的蓝牙特征值
   - 检查设备的服务和特征值配置

## 开发说明

### 主要文件结构

```
lib/
└── main.dart          # 主应用文件，包含所有蓝牙功能
```

### 核心功能实现

- **权限检查**: `_checkBluetoothPermissions()`
- **设备扫描**: `_startScan()` 和 `_stopScan()`
- **设备连接**: `_connectToDevice()`
- **服务发现**: `_discoverServices()`
- **数据发送**: `_sendData()`
- **连接断开**: `_disconnect()`

## 许可证

本项目仅用于演示目的。
