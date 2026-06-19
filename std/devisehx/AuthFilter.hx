package devisehx;

/**
	Typed auth-filter carrier for controller lifecycle declarations.

	Later compiler/generator slices lower this to Rails' normal
	`before_action :authenticate_user!` shape. Keeping it as a first-class type
	now prevents auth filters from being modeled as loose strings.
**/
final class AuthFilter<TModel> {
	public final scope:DeviseScope<TModel>;

	private function new(scope:DeviseScope<TModel>) {
		this.scope = scope;
	}

	public static function forScope<TModel>(scope:DeviseScope<TModel>):AuthFilter<TModel> {
		return new AuthFilter(scope);
	}
}
