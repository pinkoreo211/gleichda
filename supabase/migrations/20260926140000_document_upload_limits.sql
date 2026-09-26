-- What the bucket itself accepts.
--
-- The app already refuses anything over 10 MB and anything that is not a
-- PDF or a photo. That check runs on the phone, which is the right place
-- to be quick about it -- and the wrong place to rely on. A client that
-- skipped it could still put a 50 MB file of any kind into its own folder.
--
-- These two settings say the same thing where it holds: the storage
-- service refuses the request before a byte is written. The limit matches
-- `maxDocumentBytes` in the app, and the list matches the extensions the
-- picker offers.

update storage.buckets
   set file_size_limit = 10485760,
       allowed_mime_types = array[
         'application/pdf',
         'image/jpeg',
         'image/png',
         'image/heic',
         'image/webp'
       ]
 where id = 'provider-documents';
