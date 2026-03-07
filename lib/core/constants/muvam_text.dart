import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:muvam/core/utils/extension.dart';

enum TextStyleEnum {
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  button,
  label,
}

@immutable
class MuvamTexts {
  const MuvamTexts._();

  static TextStyle textStyleSwitch(
    BuildContext context,
    TextStyleEnum textStyleEnum,
  ) {
    return switch (textStyleEnum) {
      TextStyleEnum.headlineLarge => context.textTheme.headlineLarge!,
      TextStyleEnum.headlineMedium => context.textTheme.headlineMedium!,
      TextStyleEnum.headlineSmall => context.textTheme.headlineSmall!,
      TextStyleEnum.titleLarge => context.textTheme.titleLarge!,
      TextStyleEnum.titleMedium => context.textTheme.titleMedium!,
      TextStyleEnum.titleSmall => context.textTheme.titleSmall!,
      TextStyleEnum.bodyLarge => context.textTheme.bodyLarge!,
      TextStyleEnum.bodyMedium => context.textTheme.bodyMedium!,
      TextStyleEnum.bodySmall => context.textTheme.bodySmall!,
      TextStyleEnum.button => context.textTheme.labelLarge!,
      TextStyleEnum.label => context.textTheme.labelSmall!,
    };
  }

  static Widget headlineLarge32(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    double? fontSize,
    double? height,
  }) {
    final style = (context.textTheme.headlineLarge ?? const TextStyle())
        .copyWith(
          fontFamily: 'Inter',
          fontWeight: fontWeight ?? FontWeight.w700,
          color: color,
          fontSize: fontSize,
          height: height,
        );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget headlineMedium28(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    double? fontSize,
    double? height,
  }) {
    final style = (context.textTheme.headlineMedium ?? const TextStyle())
        .copyWith(
          fontFamily: 'Inter',
          fontWeight: fontWeight ?? FontWeight.w700,
          color: color,
          fontSize: fontSize,
          height: height,
        );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget headlineSmall24(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    double? fontSize,
    double? height,
  }) {
    final style = (context.textTheme.headlineSmall ?? const TextStyle())
        .copyWith(
          fontFamily: 'Inter',
          fontWeight: fontWeight ?? FontWeight.w700,
          color: color,
          fontSize: fontSize,
          height: height,
        );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget titleLarge22(
    BuildContext context, {
    required String text,
    bool isTextWidget = false,
    bool center = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    double? fontSize,
    double? height,
  }) {
    final style = (context.textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      fontSize: fontSize,
      height: height,
    );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            maxFontSize: 30,
            minFontSize: 22,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget titleMedium18(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? textDecoration,
    double? fontSize,
    double? height,
  }) {
    final style = (context.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      decoration: textDecoration,
      fontSize: fontSize,
      height: height,
    );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget titleMedium20(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? textDecoration,
    double? fontSize,
    double? height,
  }) {
    final style = (context.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      decoration: textDecoration,
      fontSize: fontSize,
      height: height,
    );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget titleSmall14(
    BuildContext context, {
    required String text,
    bool isTextWidget = false,
    bool center = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? textDecoration,
    bool isResponsive = true,
    double? fontSize,
    double? height,
  }) {
    final style = (context.textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      decoration: textDecoration,
      fontSize: fontSize,
      height: height,
    );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            maxFontSize: 14,
            minFontSize: isResponsive ? 10 : 14,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget bodyLarge16(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    double? height = 1.0,
    double? letterSpacing,
    double? fontSize,
  }) {
    final style = (context.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontSize: fontSize,
    );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget bodyMedium14(
    BuildContext context, {
    required String text,
    bool isTextWidget = false,
    bool center = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    double? height = 1.0,
    TextDecoration? textDecoration,
    double? fontSize,
  }) {
    final style = (context.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      decoration: textDecoration,
      height: height,
      fontSize: fontSize,
    );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
            maxLines: maxLines,
            overflow: overflow,
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: style,
            textScaleFactor: textScaleFactor,
            softWrap: true,
          );
  }

  static Widget bodySmall12(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    double? height,
    Color? color,
    TextDecoration? textDecoration,
    bool softWrap = true,
    double? fontSize,
  }) {
    final style = (context.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
      decoration: textDecoration,
      fontSize: fontSize,
    );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
            maxLines: maxLines,
            overflow: overflow,
            softWrap: softWrap,
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            softWrap: softWrap,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget button16(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    Color? color,
    bool responsive = false,
    TextStyle? textStyle,
    double? fontSize,
    double? height,
  }) {
    final style =
        textStyle ??
        (context.textTheme.labelLarge ?? const TextStyle()).copyWith(
          fontFamily: 'Inter',
          fontWeight: fontWeight ?? FontWeight.w600,
          color: color,
          fontSize: fontSize,
          height: height,
        );
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: style,
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            minFontSize: 18,
            style: style,
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget richText(
    BuildContext context, {
    required String text,
    TextOverflow? overflow,
    int? maxLines,
    bool center = false,
    List<InlineSpan> textChildren = const [],
    TextStyle? textStyle,
    TextStyleEnum? textStyleEnum,
    Function(PointerEnterEvent)? onEnter,
  }) {
    assert(
      textStyleEnum != null || textStyle != null,
      'You must pass either "textStyle" or "textStyleEnum"',
    );
    return AutoSizeText.rich(
      TextSpan(
        text: text,
        style: textStyle ?? textStyleSwitch(context, textStyleEnum!),
        children: textChildren,
        onEnter: onEnter,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
  }
}
