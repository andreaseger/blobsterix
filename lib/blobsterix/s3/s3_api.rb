module Blobsterix
	class S3Api < AppRouterBase
		include S3UrlHelper

		get "/", :list_buckets

		get "/*bucket_or_file.:format", :get_file
		get "/*bucket_or_file", :get_file

		head "/*bucket_or_file.:format", :get_file_head
		head "/*bucket_or_file", :get_file_head

		put "/", :create_bucket

		put "/*file.:format", :upload_data
		put "/*file", :upload_data

		delete "/", :delete_bucket
		delete "/*file.:format", :delete_file
		delete "/*file", :delete_file

		get "*any", :next_api
		put "*any", :next_api
		delete "*any", :next_api
    head "*any", :next_api
    post "*any", :next_api

		private
			def list_buckets
				Http.OK storage.list(bucket).to_xml, "xml"
			end

			def get_file(send_with_data=true)
				return Http.NotFound if favicon

				if bucket?
					if meta = storage.get(bucket, file)
						send_with_data ? meta.response(true, env["HTTP_IF_NONE_MATCH"], env, env["HTTP_X_FILE"] === "yes", false) : meta.response(false)
					else
						Http.NotFound
					end
				else
					Http.OK storage.list(bucket).to_xml, "xml"
				end
			end

			def get_file_head
				get_file(false)
			end

			def create_bucket
				Http.OK storage.create(bucket), "xml"
			end

			def upload_data
				source = cached_upload
				accept = source.accept_type()

				trafo_current = trafo(trafo_string)
				file_current = file
				bucket_current = bucket
				logger.info "UploadFile => Bucket: #{bucket_current} - File: #{file_current} - Accept: #{accept.type} - Trafo: #{trafo_current}"
				blob_access=BlobAccess.new(:source => source, :bucket => bucket_current, :id => file_current, :accept_type => accept, :trafo => trafo_current)
				data = transformation.run(blob_access)
				cached_upload_clear
				storage.put(bucket_current, file_current, data).response(false)
			end

			def delete_bucket
				if bucket?
					Http.OK_no_data storage.delete(bucket), "xml"
				else
					Http.NotFound "no such bucket"
				end
			end

			def delete_file
				if bucket?
					Http.OK_no_data storage.delete_key(bucket, file), "xml"
				else
					Http.NotFound "no such bucket"
				end
			end
	end
end
