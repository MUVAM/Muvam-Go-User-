import 'package:flutter/material.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/extension.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:muvam/core/utils/app_logger.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final VoidCallback onPaymentSuccess;

  const PaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    AppLogger.log('PaymentWebViewScreen initialized', tag: 'PAYMENT');
    AppLogger.log(
      'Authorization URL: ${widget.authorizationUrl}',
      tag: 'PAYMENT',
    );
    AppLogger.log('Payment Reference: ${widget.reference}', tag: 'PAYMENT');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            AppLogger.log('Page loading started: $url', tag: 'PAYMENT');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            AppLogger.log('Page loading finished: $url', tag: 'PAYMENT');
            setState(() {
              _isLoading = false;
            });

            // Check if payment was successful
            if (url.contains('success') || url.contains('callback')) {
              AppLogger.log(
                'Payment SUCCESS detected in URL: $url',
                tag: 'PAYMENT',
              );
              AppLogger.log(
                'Calling onPaymentSuccess callback',
                tag: 'PAYMENT',
              );
              widget.onPaymentSuccess();
              AppLogger.log(
                'Navigating back with success result',
                tag: 'PAYMENT',
              );
              context.pop(true);
            } else {
              AppLogger.log(
                'Payment still in progress, URL: $url',
                tag: 'PAYMENT',
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            AppLogger.log('Navigation request: ${request.url}', tag: 'PAYMENT');

            if (request.url.contains('success') ||
                request.url.contains('callback')) {
              AppLogger.log(
                'SUCCESS URL intercepted: ${request.url}',
                tag: 'PAYMENT',
              );
              AppLogger.log(
                'Calling onPaymentSuccess callback from navigation',
                tag: 'PAYMENT',
              );
              widget.onPaymentSuccess();
              AppLogger.log(
                'Navigating back with success result from navigation',
                tag: 'PAYMENT',
              );
              context.pop(true);
              return NavigationDecision.prevent;
            }

            AppLogger.log(
              'Allowing navigation to: ${request.url}',
              tag: 'PAYMENT',
            );
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error(
              'WebView error occurred',
              error:
                  'Code: ${error.errorCode}, Description: ${error.description}',
              tag: 'PAYMENT',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));

    AppLogger.log(
      'WebView controller configured and loading request',
      tag: 'PAYMENT',
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('Building PaymentWebViewScreen UI', tag: 'PAYMENT');

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.kBlackColor),
          onPressed: () {
            AppLogger.log(
              'User cancelled payment via close button',
              tag: 'PAYMENT',
            );
            context.pop(false);
          },
        ),
        title: MuvamTexts.titleMedium18(
          context,
          text: 'Payment',
          fontWeight: FontWeight.w600,
          color: AppColors.kBlackColor,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: AppColors.kMainColor),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.log('PaymentWebViewScreen disposed', tag: 'PAYMENT');
    super.dispose();
  }
}
