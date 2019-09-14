Paperclip::Attachment.default_options[:path] = ":class/:attachment/:id_partition/:style/:filename"
# Paperclip::Attachment.default_options[:url] = ':gcs_domain_url'
Paperclip::Attachment.default_options[:fog_host] = Rails.application.secrets.google_bucket[:host]
Paperclip::Attachment.default_options[:fog_directory] = Rails.application.secrets.google_bucket[:bucket_name]
