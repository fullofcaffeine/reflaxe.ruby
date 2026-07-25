/**
 * RubyHx publishes only immutable GitHub Release assets. Semantic-release
 * bundles its npm-registry publisher even when an explicit plugin list omits
 * it, so this local package occupies that unused dependency slot without
 * installing the registry publisher's executable dependency tree.
 *
 * Every hook fails closed. If a future configuration accidentally selects
 * `@semantic-release/npm`, publication stops before it can contact a registry.
 */
function registryPublicationDisabled() {
  throw new Error(
    "@semantic-release/npm is disabled: RubyHx publishes only through the reviewed GitHub Releases workflow."
  );
}

export const verifyConditions = registryPublicationDisabled;
export const prepare = registryPublicationDisabled;
export const publish = registryPublicationDisabled;
export const addChannel = registryPublicationDisabled;
