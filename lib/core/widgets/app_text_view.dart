import 'package:flutter/material.dart';

class AppTextView extends StatelessWidget {
  const AppTextView._(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
  });

  const AppTextView.title(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 34,
         fontWeight: fontWeight ?? FontWeight.w700,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  const AppTextView.title1(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 24,
         fontWeight: fontWeight ?? FontWeight.w700,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  const AppTextView.subTitle(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 16,
         fontWeight: fontWeight ?? FontWeight.w500,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  const AppTextView.body(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 16,
         fontWeight: fontWeight ?? FontWeight.w400,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  const AppTextView.body1(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 18,
         fontWeight: fontWeight ?? FontWeight.w600,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  const AppTextView.body2(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 14,
         fontWeight: fontWeight ?? FontWeight.w500,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  const AppTextView.body3(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 12,
         fontWeight: fontWeight ?? FontWeight.w400,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  const AppTextView.body4(
    String text, {
    Key? key,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) : this._(
         text,
         key: key,
         color: color,
         fontSize: fontSize ?? 10,
         fontWeight: fontWeight ?? FontWeight.w400,
         textAlign: textAlign,
         maxLines: maxLines,
         overflow: overflow,
         height: height,
       );

  final String text;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height),
    );
  }
}
