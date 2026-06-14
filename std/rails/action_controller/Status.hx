package rails.action_controller;

/**
	Typed Rails response status token.

	The compiler lowers these tokens to Rails-native status symbols for response
	helpers such as `head(Status.noContent)` -> `head(:no_content)`.
**/
abstract Status(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline var ok:Status = new Status("ok");
	public static inline var created:Status = new Status("created");
	public static inline var accepted:Status = new Status("accepted");
	public static inline var noContent:Status = new Status("no_content");
	public static inline var seeOther:Status = new Status("see_other");
	public static inline var badRequest:Status = new Status("bad_request");
	public static inline var unauthorized:Status = new Status("unauthorized");
	public static inline var forbidden:Status = new Status("forbidden");
	public static inline var notFound:Status = new Status("not_found");
	public static inline var conflict:Status = new Status("conflict");
	public static inline var unprocessableEntity:Status = new Status("unprocessable_entity");
	public static inline var internalServerError:Status = new Status("internal_server_error");

	public static inline function named(value:String):Status {
		return new Status(value);
	}
}
