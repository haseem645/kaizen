import 'package:flutter/widgets.dart';

/// Keeps assignment details above an independently scrolling description.
class TrainingAssignmentLayout extends StatelessWidget {
  const TrainingAssignmentLayout({super.key, required this.header, required this.body});

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.75;

        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height * 0.5),
                child: SingleChildScrollView(primary: false, child: header),
              ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
