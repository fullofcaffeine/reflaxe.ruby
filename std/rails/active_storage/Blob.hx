package rails.active_storage;

/*
	Typed facade for Rails' ActiveStorage::Blob instances.

	This is an extern-style contract: Rails owns the runtime object, while Haxe
	gets completion and types for the blob metadata/direct-upload methods that
	are safe to consume from RailsHx app code.
 */
@:native("ActiveStorage::Blob")
extern class Blob {
	@:native("signed_id")
	public function signedId():SignedId;

	public function filename():Filename;

	@:native("content_type")
	public function contentType():Null<String>;

	@:native("byte_size")
	public function byteSize():Int;

	public function metadata():Dynamic;

	@:native("service_url_for_direct_upload")
	public function serviceUrlForDirectUpload():String;

	@:native("service_headers_for_direct_upload")
	public function serviceHeadersForDirectUpload():Dynamic;
}
