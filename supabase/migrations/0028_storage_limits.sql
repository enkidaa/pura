-- Neither bucket had file_size_limit/allowed_mime_types set — any file of
-- any size/type could be uploaded. Documents are referti (PDF or a photo
-- of one); skincare photos are always a single camera-captured JPEG.
--
-- 10MB for documents: generous enough for a multi-page scanned PDF, small
-- enough to keep a runaway/malicious upload from being a real storage or
-- cost problem. 5MB for skincare photos: a single phone camera JPEG is
-- typically 2-5MB, so this has headroom without being effectively
-- unlimited.
update storage.buckets
set file_size_limit = 10 * 1024 * 1024,
    allowed_mime_types = array['application/pdf', 'image/jpeg', 'image/png']
where id = 'user-documents';

update storage.buckets
set file_size_limit = 5 * 1024 * 1024,
    allowed_mime_types = array['image/jpeg', 'image/png']
where id = 'skincare-photos';
