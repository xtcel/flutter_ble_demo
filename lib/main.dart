import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const BluetoothDemoApp());
}

class BluetoothDemoApp extends StatelessWidget {
  const BluetoothDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BluetoothHomePage(),
    );
  }
}

class BluetoothHomePage extends StatefulWidget {
  const BluetoothHomePage({super.key});

  @override
  State<BluetoothHomePage> createState() => _BluetoothHomePageState();
}

class _BluetoothHomePageState extends State<BluetoothHomePage> {
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  bool isScanning = false;
  bool isConnected = false;
  String receivedData = '';
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkBluetoothPermissions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      
      if (statuses.values.any((status) => status.isDenied)) {
        _showSnackBar('请授予蓝牙和位置权限以使用此功能');
      }
    }
  }

  Future<void> _startScan() async {
    if (isScanning) return;
    
    setState(() {
      isScanning = true;
      devicesList.clear();
    });

    try {
      // 检查蓝牙是否开启
      if (await FlutterBluePlus.isSupported == false) {
        _showSnackBar('设备不支持蓝牙');
        return;
      }

      // 开始扫描
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      // 监听扫描结果
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!devicesList.contains(result.device) && result.device.platformName.isNotEmpty) {
            setState(() {
              devicesList.add(result.device);
            });
          }
        }
      });

      // 10秒后停止扫描
      Future.delayed(const Duration(seconds: 10), () {
        _stopScan();
      });
    } catch (e) {
      _showSnackBar('扫描失败: $e');
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        isConnected = true;
      });
      
      _showSnackBar('已连接到 ${device.platformName}');
      
      // 发现服务
      await _discoverServices(device);
    } catch (e) {
      _showSnackBar('连接失败: $e');
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // 寻找可写入和可通知的特征
          if (characteristic.properties.write && characteristic.properties.notify) {
            targetCharacteristic = characteristic;
            
            // 启用通知
            await characteristic.setNotifyValue(true);
            
            // 监听数据
            characteristic.lastValueStream.listen((value) {
              setState(() {
                receivedData = utf8.decode(value);
              });
            });
            
            break;
          }
        }
        if (targetCharacteristic != null) break;
      }
      
      if (targetCharacteristic == null) {
        _showSnackBar('未找到合适的特征值');
      }
    } catch (e) {
      _showSnackBar('发现服务失败: $e');
    }
  }

  Future<void> _disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        isConnected = false;
        targetCharacteristic = null;
        receivedData = '';
      });
      _showSnackBar('已断开连接');
    }
  }

  Future<void> _sendData(String message) async {
    if (targetCharacteristic != null && message.isNotEmpty) {
      try {
        List<int> bytes = utf8.encode(message);
        await targetCharacteristic!.write(bytes);
        _showSnackBar('数据已发送: $message');
        _messageController.clear();
      } catch (e) {
        _showSnackBar('发送失败: $e');
      }
    } else {
      _showSnackBar('请先连接设备或输入消息');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 连接状态
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '连接状态: ${isConnected ? "已连接" : "未连接"}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (connectedDevice != null)
                      Text('设备: ${connectedDevice!.platformName}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 扫描按钮
            ElevatedButton(
              onPressed: isScanning ? null : _startScan,
              child: Text(isScanning ? '扫描中...' : '扫描设备'),
            ),
            const SizedBox(height: 16),
            
            // 设备列表
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '发现的设备',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: devicesList.length,
                        itemBuilder: (context, index) {
                          BluetoothDevice device = devicesList[index];
                          return ListTile(
                            title: Text(device.platformName.isEmpty ? '未知设备' : device.platformName),
                            subtitle: Text(device.remoteId.toString()),
                            trailing: ElevatedButton(
                              onPressed: isConnected ? null : () => _connectToDevice(device),
                              child: const Text('连接'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 数据发送
            if (isConnected)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '发送数据',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: '输入要发送的消息',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _sendData(_messageController.text),
                            child: const Text('发送'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // 接收数据
            if (isConnected)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '接收数据',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                receivedData.isEmpty ? '暂无数据' : receivedData,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // 断开连接按钮
            if (isConnected)
              ElevatedButton(
                onPressed: _disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('断开连接'),
              ),
          ],
        ),
      ),
    );
  }
}
