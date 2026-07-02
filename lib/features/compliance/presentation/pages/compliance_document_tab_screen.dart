import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../providers/compliance_document_controller.dart';
import '../widgets/compliance_empty_state.dart';
import '../widgets/compliance_search_bar.dart';
import '../widgets/document_card.dart';

class ComplianceDocumentTabScreen extends StatelessWidget {
  const ComplianceDocumentTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComplianceDocumentController>();
    final documents = controller.filteredDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ComplianceSearchBar(
          controller: controller.searchController,
          onChanged: controller.updateSearchQuery,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: documents.isEmpty
              ? const ComplianceEmptyState(
                  message: AppStrings.complianceNoDocumentsFound,
                )
              : ListView.separated(
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return DocumentCard(document: documents[index]);
                  },
                ),
        ),
      ],
    );
  }
}
