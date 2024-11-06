# Supsis Flutter Widget

**Supsis Flutter Widget**, Flutter uygulamalarınıza kolayca entegre edebileceğiniz özelleştirilebilir bir sohbet bileşenidir. Bu bileşen, kullanıcılarınızın destek ekibinizle gerçek zamanlı olarak iletişim kurmasını sağlar.

## Özellikler

- **Kolay Entegrasyon**: Uygulamanıza minimum çabayla sohbet bileşeni ekleyin.
- **Özelleştirilebilir**: Kullanıcı verilerini ve departmanı ayarlayarak kişiselleştirilmiş destek sunun.
- **Duyarlı Arayüz**: Bileşen, farklı ekran boyutlarına ve yönlendirmelerine sorunsuz bir şekilde uyum sağlar.
- **Gerçek Zamanlı İletişim**: Kullanıcılarınız ve destek ekibiniz arasında anlık mesajlaşma imkanı sağlar.

## Gereklilikler

- **Flutter SDK 2.0** veya üzeri
- **İnternet İzni**: Uygulamanızın internet erişimine izin vermesi gerekir. `AndroidManifest.xml` dosyanıza aşağıdaki izni ekleyin:

  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```

## Kurulum

Bu kütüphane pub.dev üzerinden dağıtılmaktadır. Projenize eklemek için aşağıdaki adımları izleyin:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supsis_flutter_widget: ^0.0.1
```

- Paketleri indirmek için terminalde şu komutu çalıştırın:

```bash
flutter pub get
```

## Kullanım

SupsisVisitor widget'ını kullanmak için, dart dosyanıza dahil edin ve widget ağacınıza ekleyin.

`main.dart` Dosyası:

```dart
import 'package:flutter/material.dart';
import 'package:supsis_flutter_widget/supsis_flutter_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SupsisVisitorController _controller = SupsisVisitorController();

  @override
  void initState() {
    super.initState();

    // Otomatik olarak kullanıcı verilerini ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.setUserData({
        'name': 'Ahmet Yılmaz',
        'email': 'ahmet.yilmaz@example.com',
      });
      _controller.setContactProperty({
        'phone': '05551234567',
        'address': '123 Ana Cadde',
      });
    });
  }

  // clearCache fonksiyonunu tanımla ancak kullanma
  void clearCache() {
    _controller.clearCache();
    print('Cache cleared.');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Debug modunu kapat
      home: Scaffold(
        appBar: AppBar(
          title: Text("Supsis Visitor"),
        ),
        body: SupsisVisitor(
          controller: _controller,
          // Kendi domain adınızı girin
          domainName: 'sizin_domain_adiniz',
          environment: 'prod', // veya 'beta'
          onConnected: () {
            print('Visitor connected');
          },
          onDisconnected: () {
            print('Visitor disconnected');
          },
        ),
        // WebView görünürse FloatingActionButton'u gösterme
        floatingActionButton: !_controller.isVisible
            ? Padding(
                padding: const EdgeInsets.only(bottom: 64.0, right: 16),
                child: FloatingActionButton(
                  onPressed: () {
                    _controller.open();
                    print('WebView opened.');
                  },
                  child: Icon(Icons.chat),
                ),
              )
            : null,
      ),
    );
  }
}

```

## Fonksiyonların Açıklaması

|                         Fonksiyon                          |                      Açıklama                      |                                     Kullanım Örneği                                     |
| :--------------------------------------------------------: | :------------------------------------------------: | :-------------------------------------------------------------------------------------: |
|        `setUserData(Map<String, dynamic> userData)`        | Sohbet oturumu için kullanıcı bilgilerini ayarlar. |  `_controller.setUserData({'email': 'kullanici@ornek.com', 'name': 'Ahmet Yılmaz'});`   |
| `setContactProperty(Map<String, dynamic> contactProperty)` |     Kullanıcının iletişim bilgilerini ayarlar.     | `_controller.setContactProperty({'phone': '05551234567', 'address': '123 Ana Cadde'});` |
|             `setDepartment(String department)`             |      Sohbet oturumu için departmanı ayarlar.       |                         `_controller.setDepartment('Destek');`                          |
|                          `open()`                          |  Sohbet bileşenini açar ve kullanıcıya gösterir.   |                                  `_controller.open();`                                  |
|                         `close()`                          | Sohbet bileşenini kapatır ve kullanıcıdan gizler.  |                                 `_controller.close();`                                  |
|                       `clearCache()`                       |      Sohbet oturumunun önbelleğini temizler.       |                               `_controller.clearCache();`                               |

## Örnek Uygulama

`main.dart` Dosyası:

```dart
import 'package:flutter/material.dart';
import 'package:supsis_flutter_widget/supsis_flutter_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final SupsisVisitorController _controller = SupsisVisitorController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supsis Flutter Widget Örnek',
      debugShowCheckedModeBanner: false, // Debug modunu kapat
      home: Scaffold(
        appBar: AppBar(
          title: Text('Supsis Flutter Widget Örnek'),
        ),
        body: Stack(
          children: [
            SupsisVisitor(
              controller: _controller,
              // Kendi domain adınızı girin
              domainName: 'sizin_domain_adiniz',
              environment: 'prod', // veya 'beta'
              onConnected: () {
                print('Visitor connected');
              },
              onDisconnected: () {
                print('Visitor disconnected');
              },
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _controller.open();
                      print('Sohbet açıldı.');
                    },
                    child: Text('Sohbeti Aç'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _controller.close();
                      print('Sohbet kapatıldı.');
                    },
                    child: Text('Sohbeti Kapat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Lisans

Bu proje MIT Lisansı altında lisanslanmıştır.

## Destek

Herhangi bir sorunla karşılaşırsanız veya sorunuz varsa, lütfen GitHub deposu üzerinden bir sorun (issue) açın.
