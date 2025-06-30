import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

class DocumentService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Upload a document for driver verification
  static Future<bool> uploadDocument({
    required String documentType,
    required String filePath,
    required String fileName,
    DateTime? expiresAt,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload file to storage
      final fileExt = fileName.split('.').last;
      final storagePath = 'documents/${user.id}/$documentType.$fileExt';
      
      await _client.storage
          .from('driver-documents')
          .upload(storagePath, filePath);

      // Get public URL
      final documentUrl = _client.storage
          .from('driver-documents')
          .getPublicUrl(storagePath);

      // Save document record to database
      await _client.from('driver_documents').upsert({
        'driver_id': user.id,
        'document_type': documentType,
        'document_url': documentUrl,
        'status': 'pending',
        'expires_at': expiresAt?.toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error uploading document: $e');
      return false;
    }
  }

  // Get driver documents
  static Future<List<DriverDocument>> getDriverDocuments() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('driver_documents')
          .select()
          .eq('driver_id', user.id)
          .order('created_at', ascending: false);

      return response.map((json) => DriverDocument.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching driver documents: $e');
      return [];
    }
  }

  // Check if driver has all required documents approved
  static Future<bool> hasAllDocumentsApproved() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final result = await _client.rpc('check_driver_documents_complete', 
          params: {'driver_uuid': user.id});
      
      return result as bool;
    } catch (e) {
      print('Error checking document completion: $e');
      return false;
    }
  }

  // Get document verification status
  static Future<Map<String, String>> getDocumentStatus() async {
    try {
      final documents = await getDriverDocuments();
      final status = <String, String>{};
      
      for (final doc in documents) {
        status[doc.documentType] = doc.status;
      }
      
      return status;
    } catch (e) {
      print('Error getting document status: $e');
      return {};
    }
  }

  // Delete a document
  static Future<bool> deleteDocument(String documentId) async {
    try {
      await _client
          .from('driver_documents')
          .delete()
          .eq('id', documentId);
      
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }
}