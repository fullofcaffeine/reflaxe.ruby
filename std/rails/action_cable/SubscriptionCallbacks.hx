package rails.action_cable;

typedef SubscriptionCallbacks<TPayload> = {
	var ?connected:Void->Void;
	var ?disconnected:Void->Void;
	var ?rejected:Void->Void;
	var ?received:TPayload->Void;
}
