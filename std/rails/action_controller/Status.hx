package rails.action_controller;

/**
	Typed Rails response status token.

	The compiler lowers these tokens to Rails-native status symbols for response
	helpers such as `head(Status.noContent)` -> `head(:no_content)`.
**/
abstract Status(String) from String to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline var ok:Status = "ok";
	public static inline var created:Status = "created";
	public static inline var accepted:Status = "accepted";
	public static inline var noContent:Status = "no_content";
	public static inline var seeOther:Status = "see_other";
	public static inline var badRequest:Status = "bad_request";
	public static inline var unauthorized:Status = "unauthorized";
	public static inline var forbidden:Status = "forbidden";
	public static inline var notFound:Status = "not_found";
	public static inline var conflict:Status = "conflict";
	public static inline var unprocessableEntity:Status = "unprocessable_entity";
	public static inline var internalServerError:Status = "internal_server_error";

	public static inline function named(value:String):Status {
		return new Status(value);
	}
}
