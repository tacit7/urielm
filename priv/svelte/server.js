var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __esm = (fn, res) => function __init() {
  return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
};
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key2 of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key2) && key2 !== except)
        __defProp(to, key2, { get: () => from[key2], enumerable: !(desc = __getOwnPropDesc(from, key2)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// node_modules/svelte/src/constants.js
var EACH_ITEM_REACTIVE, EACH_INDEX_REACTIVE, EACH_IS_CONTROLLED, EACH_IS_ANIMATED, EACH_ITEM_IMMUTABLE, PROPS_IS_IMMUTABLE, PROPS_IS_RUNES, PROPS_IS_UPDATED, PROPS_IS_BINDABLE, PROPS_IS_LAZY_INITIAL, TRANSITION_IN, TRANSITION_OUT, TRANSITION_GLOBAL, TEMPLATE_FRAGMENT, TEMPLATE_USE_IMPORT_NODE, TEMPLATE_USE_SVG, TEMPLATE_USE_MATHML, HYDRATION_START, HYDRATION_START_ELSE, HYDRATION_END, HYDRATION_ERROR, ELEMENT_IS_NAMESPACED, ELEMENT_PRESERVE_ATTRIBUTE_CASE, ELEMENT_IS_INPUT, UNINITIALIZED, FILENAME, HMR, NAMESPACE_HTML, NAMESPACE_SVG, NAMESPACE_MATHML, ATTACHMENT_KEY;
var init_constants = __esm({
  "node_modules/svelte/src/constants.js"() {
    EACH_ITEM_REACTIVE = 1;
    EACH_INDEX_REACTIVE = 1 << 1;
    EACH_IS_CONTROLLED = 1 << 2;
    EACH_IS_ANIMATED = 1 << 3;
    EACH_ITEM_IMMUTABLE = 1 << 4;
    PROPS_IS_IMMUTABLE = 1;
    PROPS_IS_RUNES = 1 << 1;
    PROPS_IS_UPDATED = 1 << 2;
    PROPS_IS_BINDABLE = 1 << 3;
    PROPS_IS_LAZY_INITIAL = 1 << 4;
    TRANSITION_IN = 1;
    TRANSITION_OUT = 1 << 1;
    TRANSITION_GLOBAL = 1 << 2;
    TEMPLATE_FRAGMENT = 1;
    TEMPLATE_USE_IMPORT_NODE = 1 << 1;
    TEMPLATE_USE_SVG = 1 << 2;
    TEMPLATE_USE_MATHML = 1 << 3;
    HYDRATION_START = "[";
    HYDRATION_START_ELSE = "[!";
    HYDRATION_END = "]";
    HYDRATION_ERROR = {};
    ELEMENT_IS_NAMESPACED = 1;
    ELEMENT_PRESERVE_ATTRIBUTE_CASE = 1 << 1;
    ELEMENT_IS_INPUT = 1 << 2;
    UNINITIALIZED = Symbol();
    FILENAME = Symbol("filename");
    HMR = Symbol("hmr");
    NAMESPACE_HTML = "http://www.w3.org/1999/xhtml";
    NAMESPACE_SVG = "http://www.w3.org/2000/svg";
    NAMESPACE_MATHML = "http://www.w3.org/1998/Math/MathML";
    ATTACHMENT_KEY = "@attach";
  }
});

// node_modules/svelte/src/escaping.js
function escape_html(value, is_attr) {
  const str = String(value ?? "");
  const pattern = is_attr ? ATTR_REGEX : CONTENT_REGEX;
  pattern.lastIndex = 0;
  let escaped2 = "";
  let last = 0;
  while (pattern.test(str)) {
    const i = pattern.lastIndex - 1;
    const ch = str[i];
    escaped2 += str.substring(last, i) + (ch === "&" ? "&amp;" : ch === '"' ? "&quot;" : "&lt;");
    last = i + 1;
  }
  return escaped2 + str.substring(last);
}
var ATTR_REGEX, CONTENT_REGEX;
var init_escaping = __esm({
  "node_modules/svelte/src/escaping.js"() {
    ATTR_REGEX = /[&"<]/g;
    CONTENT_REGEX = /[&<]/g;
  }
});

// node_modules/clsx/dist/clsx.mjs
function r(e) {
  var t, f, n = "";
  if ("string" == typeof e || "number" == typeof e) n += e;
  else if ("object" == typeof e) if (Array.isArray(e)) {
    var o = e.length;
    for (t = 0; t < o; t++) e[t] && (f = r(e[t])) && (n && (n += " "), n += f);
  } else for (f in e) e[f] && (n && (n += " "), n += f);
  return n;
}
function clsx() {
  for (var e, t, f = 0, n = "", o = arguments.length; f < o; f++) (e = arguments[f]) && (t = r(e)) && (n && (n += " "), n += t);
  return n;
}
var init_clsx = __esm({
  "node_modules/clsx/dist/clsx.mjs"() {
  }
});

// node_modules/svelte/src/internal/shared/attributes.js
function attr(name, value, is_boolean = false) {
  if (name === "hidden" && value !== "until-found") {
    is_boolean = true;
  }
  if (value == null || !value && is_boolean) return "";
  const normalized = name in replacements && replacements[name].get(value) || value;
  const assignment = is_boolean ? "" : `="${escape_html(normalized, true)}"`;
  return ` ${name}${assignment}`;
}
function clsx2(value) {
  if (typeof value === "object") {
    return clsx(value);
  } else {
    return value ?? "";
  }
}
function to_class(value, hash2, directives) {
  var classname = value == null ? "" : "" + value;
  if (hash2) {
    classname = classname ? classname + " " + hash2 : hash2;
  }
  if (directives) {
    for (var key2 in directives) {
      if (directives[key2]) {
        classname = classname ? classname + " " + key2 : key2;
      } else if (classname.length) {
        var len = key2.length;
        var a = 0;
        while ((a = classname.indexOf(key2, a)) >= 0) {
          var b = a + len;
          if ((a === 0 || whitespace.includes(classname[a - 1])) && (b === classname.length || whitespace.includes(classname[b]))) {
            classname = (a === 0 ? "" : classname.substring(0, a)) + classname.substring(b + 1);
          } else {
            a = b;
          }
        }
      }
    }
  }
  return classname === "" ? null : classname;
}
function append_styles(styles, important = false) {
  var separator = important ? " !important;" : ";";
  var css = "";
  for (var key2 in styles) {
    var value = styles[key2];
    if (value != null && value !== "") {
      css += " " + key2 + ": " + value + separator;
    }
  }
  return css;
}
function to_css_name(name) {
  if (name[0] !== "-" || name[1] !== "-") {
    return name.toLowerCase();
  }
  return name;
}
function to_style(value, styles) {
  if (styles) {
    var new_style = "";
    var normal_styles;
    var important_styles;
    if (Array.isArray(styles)) {
      normal_styles = styles[0];
      important_styles = styles[1];
    } else {
      normal_styles = styles;
    }
    if (value) {
      value = String(value).replaceAll(/\s*\/\*.*?\*\/\s*/g, "").trim();
      var in_str = false;
      var in_apo = 0;
      var in_comment = false;
      var reserved_names = [];
      if (normal_styles) {
        reserved_names.push(...Object.keys(normal_styles).map(to_css_name));
      }
      if (important_styles) {
        reserved_names.push(...Object.keys(important_styles).map(to_css_name));
      }
      var start_index = 0;
      var name_index = -1;
      const len = value.length;
      for (var i = 0; i < len; i++) {
        var c = value[i];
        if (in_comment) {
          if (c === "/" && value[i - 1] === "*") {
            in_comment = false;
          }
        } else if (in_str) {
          if (in_str === c) {
            in_str = false;
          }
        } else if (c === "/" && value[i + 1] === "*") {
          in_comment = true;
        } else if (c === '"' || c === "'") {
          in_str = c;
        } else if (c === "(") {
          in_apo++;
        } else if (c === ")") {
          in_apo--;
        }
        if (!in_comment && in_str === false && in_apo === 0) {
          if (c === ":" && name_index === -1) {
            name_index = i;
          } else if (c === ";" || i === len - 1) {
            if (name_index !== -1) {
              var name = to_css_name(value.substring(start_index, name_index).trim());
              if (!reserved_names.includes(name)) {
                if (c !== ";") {
                  i++;
                }
                var property = value.substring(start_index, i).trim();
                new_style += " " + property + ";";
              }
            }
            start_index = i + 1;
            name_index = -1;
          }
        }
      }
    }
    if (normal_styles) {
      new_style += append_styles(normal_styles);
    }
    if (important_styles) {
      new_style += append_styles(important_styles, true);
    }
    new_style = new_style.trim();
    return new_style === "" ? null : new_style;
  }
  return value == null ? null : String(value);
}
var replacements, whitespace;
var init_attributes = __esm({
  "node_modules/svelte/src/internal/shared/attributes.js"() {
    init_escaping();
    init_clsx();
    replacements = {
      translate: /* @__PURE__ */ new Map([
        [true, "yes"],
        [false, "no"]
      ])
    };
    whitespace = [..." 	\n\r\f\xA0\v\uFEFF"];
  }
});

// node_modules/svelte/src/internal/shared/utils.js
function is_function(thing) {
  return typeof thing === "function";
}
function is_promise(value) {
  return typeof value?.then === "function";
}
function run(fn) {
  return fn();
}
function run_all(arr) {
  for (var i = 0; i < arr.length; i++) {
    arr[i]();
  }
}
function deferred() {
  var resolve;
  var reject;
  var promise = new Promise((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}
function fallback(value, fallback2, lazy = false) {
  return value === void 0 ? lazy ? (
    /** @type {() => V} */
    fallback2()
  ) : (
    /** @type {V} */
    fallback2
  ) : value;
}
function to_array(value, n) {
  if (Array.isArray(value)) {
    return value;
  }
  if (n === void 0 || !(Symbol.iterator in value)) {
    return Array.from(value);
  }
  const array = [];
  for (const element2 of value) {
    array.push(element2);
    if (array.length === n) break;
  }
  return array;
}
var is_array, index_of, array_from, object_keys, define_property, get_descriptor, get_descriptors, object_prototype, array_prototype, get_prototype_of, is_extensible, noop;
var init_utils = __esm({
  "node_modules/svelte/src/internal/shared/utils.js"() {
    is_array = Array.isArray;
    index_of = Array.prototype.indexOf;
    array_from = Array.from;
    object_keys = Object.keys;
    define_property = Object.defineProperty;
    get_descriptor = Object.getOwnPropertyDescriptor;
    get_descriptors = Object.getOwnPropertyDescriptors;
    object_prototype = Object.prototype;
    array_prototype = Array.prototype;
    get_prototype_of = Object.getPrototypeOf;
    is_extensible = Object.isExtensible;
    noop = () => {
    };
  }
});

// node_modules/esm-env/false.js
var false_default;
var init_false = __esm({
  "node_modules/esm-env/false.js"() {
    false_default = false;
  }
});

// node_modules/esm-env/true.js
var true_default;
var init_true = __esm({
  "node_modules/esm-env/true.js"() {
    true_default = true;
  }
});

// node_modules/esm-env/index.js
var init_esm_env = __esm({
  "node_modules/esm-env/index.js"() {
    init_false();
    init_true();
    init_true();
  }
});

// node_modules/svelte/src/internal/client/constants.js
var DERIVED, EFFECT, RENDER_EFFECT, MANAGED_EFFECT, BLOCK_EFFECT, BRANCH_EFFECT, ROOT_EFFECT, BOUNDARY_EFFECT, CONNECTED, CLEAN, DIRTY, MAYBE_DIRTY, INERT, DESTROYED, EFFECT_RAN, EFFECT_TRANSPARENT, EAGER_EFFECT, HEAD_EFFECT, EFFECT_PRESERVED, USER_EFFECT, WAS_MARKED, REACTION_IS_UPDATING, ASYNC, ERROR_VALUE, STATE_SYMBOL, LEGACY_PROPS, LOADING_ATTR_SYMBOL, PROXY_PATH_SYMBOL, STALE_REACTION, ELEMENT_NODE, TEXT_NODE, COMMENT_NODE, DOCUMENT_FRAGMENT_NODE;
var init_constants2 = __esm({
  "node_modules/svelte/src/internal/client/constants.js"() {
    DERIVED = 1 << 1;
    EFFECT = 1 << 2;
    RENDER_EFFECT = 1 << 3;
    MANAGED_EFFECT = 1 << 24;
    BLOCK_EFFECT = 1 << 4;
    BRANCH_EFFECT = 1 << 5;
    ROOT_EFFECT = 1 << 6;
    BOUNDARY_EFFECT = 1 << 7;
    CONNECTED = 1 << 9;
    CLEAN = 1 << 10;
    DIRTY = 1 << 11;
    MAYBE_DIRTY = 1 << 12;
    INERT = 1 << 13;
    DESTROYED = 1 << 14;
    EFFECT_RAN = 1 << 15;
    EFFECT_TRANSPARENT = 1 << 16;
    EAGER_EFFECT = 1 << 17;
    HEAD_EFFECT = 1 << 18;
    EFFECT_PRESERVED = 1 << 19;
    USER_EFFECT = 1 << 20;
    WAS_MARKED = 1 << 15;
    REACTION_IS_UPDATING = 1 << 21;
    ASYNC = 1 << 22;
    ERROR_VALUE = 1 << 23;
    STATE_SYMBOL = Symbol("$state");
    LEGACY_PROPS = Symbol("legacy props");
    LOADING_ATTR_SYMBOL = Symbol("");
    PROXY_PATH_SYMBOL = Symbol("proxy path");
    STALE_REACTION = new class StaleReactionError extends Error {
      name = "StaleReactionError";
      message = "The reaction that called `getAbortSignal()` was re-run or destroyed";
    }();
    ELEMENT_NODE = 1;
    TEXT_NODE = 3;
    COMMENT_NODE = 8;
    DOCUMENT_FRAGMENT_NODE = 11;
  }
});

// node_modules/svelte/src/internal/shared/errors.js
function experimental_async_required(name) {
  if (true_default) {
    const error = new Error(`experimental_async_required
Cannot use \`${name}(...)\` unless the \`experimental.async\` compiler option is \`true\`
https://svelte.dev/e/experimental_async_required`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/experimental_async_required`);
  }
}
function invalid_default_snippet() {
  if (true_default) {
    const error = new Error(`invalid_default_snippet
Cannot use \`{@render children(...)}\` if the parent component uses \`let:\` directives. Consider using a named snippet instead
https://svelte.dev/e/invalid_default_snippet`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/invalid_default_snippet`);
  }
}
function invalid_snippet_arguments() {
  if (true_default) {
    const error = new Error(`invalid_snippet_arguments
A snippet function was passed invalid arguments. Snippets should only be instantiated via \`{@render ...}\`
https://svelte.dev/e/invalid_snippet_arguments`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/invalid_snippet_arguments`);
  }
}
function lifecycle_outside_component(name) {
  if (true_default) {
    const error = new Error(`lifecycle_outside_component
\`${name}(...)\` can only be used during component initialisation
https://svelte.dev/e/lifecycle_outside_component`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/lifecycle_outside_component`);
  }
}
function snippet_without_render_tag() {
  if (true_default) {
    const error = new Error(`snippet_without_render_tag
Attempted to render a snippet without a \`{@render}\` block. This would cause the snippet code to be stringified instead of its content being rendered to the DOM. To fix this, change \`{snippet}\` to \`{@render snippet()}\`.
https://svelte.dev/e/snippet_without_render_tag`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/snippet_without_render_tag`);
  }
}
function store_invalid_shape(name) {
  if (true_default) {
    const error = new Error(`store_invalid_shape
\`${name}\` is not a store with a \`subscribe\` method
https://svelte.dev/e/store_invalid_shape`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/store_invalid_shape`);
  }
}
function svelte_element_invalid_this_value() {
  if (true_default) {
    const error = new Error(`svelte_element_invalid_this_value
The \`this\` prop on \`<svelte:element>\` must be a string, if defined
https://svelte.dev/e/svelte_element_invalid_this_value`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/svelte_element_invalid_this_value`);
  }
}
var init_errors = __esm({
  "node_modules/svelte/src/internal/shared/errors.js"() {
    init_esm_env();
  }
});

// node_modules/svelte/src/internal/client/errors.js
function async_derived_orphan() {
  if (true_default) {
    const error = new Error(`async_derived_orphan
Cannot create a \`$derived(...)\` with an \`await\` expression outside of an effect tree
https://svelte.dev/e/async_derived_orphan`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/async_derived_orphan`);
  }
}
function bind_invalid_checkbox_value() {
  if (true_default) {
    const error = new Error(`bind_invalid_checkbox_value
Using \`bind:value\` together with a checkbox input is not allowed. Use \`bind:checked\` instead
https://svelte.dev/e/bind_invalid_checkbox_value`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/bind_invalid_checkbox_value`);
  }
}
function component_api_changed(method, component2) {
  if (true_default) {
    const error = new Error(`component_api_changed
Calling \`${method}\` on a component instance (of ${component2}) is no longer valid in Svelte 5
https://svelte.dev/e/component_api_changed`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/component_api_changed`);
  }
}
function component_api_invalid_new(component2, name) {
  if (true_default) {
    const error = new Error(`component_api_invalid_new
Attempted to instantiate ${component2} with \`new ${name}\`, which is no longer valid in Svelte 5. If this component is not under your control, set the \`compatibility.componentApi\` compiler option to \`4\` to keep it working.
https://svelte.dev/e/component_api_invalid_new`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/component_api_invalid_new`);
  }
}
function derived_references_self() {
  if (true_default) {
    const error = new Error(`derived_references_self
A derived value cannot reference itself recursively
https://svelte.dev/e/derived_references_self`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/derived_references_self`);
  }
}
function each_key_duplicate(a, b, value) {
  if (true_default) {
    const error = new Error(`each_key_duplicate
${value ? `Keyed each block has duplicate key \`${value}\` at indexes ${a} and ${b}` : `Keyed each block has duplicate key at indexes ${a} and ${b}`}
https://svelte.dev/e/each_key_duplicate`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/each_key_duplicate`);
  }
}
function effect_in_teardown(rune) {
  if (true_default) {
    const error = new Error(`effect_in_teardown
\`${rune}\` cannot be used inside an effect cleanup function
https://svelte.dev/e/effect_in_teardown`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/effect_in_teardown`);
  }
}
function effect_in_unowned_derived() {
  if (true_default) {
    const error = new Error(`effect_in_unowned_derived
Effect cannot be created inside a \`$derived\` value that was not itself created inside an effect
https://svelte.dev/e/effect_in_unowned_derived`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/effect_in_unowned_derived`);
  }
}
function effect_orphan(rune) {
  if (true_default) {
    const error = new Error(`effect_orphan
\`${rune}\` can only be used inside an effect (e.g. during component initialisation)
https://svelte.dev/e/effect_orphan`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/effect_orphan`);
  }
}
function effect_pending_outside_reaction() {
  if (true_default) {
    const error = new Error(`effect_pending_outside_reaction
\`$effect.pending()\` can only be called inside an effect or derived
https://svelte.dev/e/effect_pending_outside_reaction`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/effect_pending_outside_reaction`);
  }
}
function effect_update_depth_exceeded() {
  if (true_default) {
    const error = new Error(`effect_update_depth_exceeded
Maximum update depth exceeded. This typically indicates that an effect reads and writes the same piece of state
https://svelte.dev/e/effect_update_depth_exceeded`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/effect_update_depth_exceeded`);
  }
}
function hydration_failed() {
  if (true_default) {
    const error = new Error(`hydration_failed
Failed to hydrate the application
https://svelte.dev/e/hydration_failed`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/hydration_failed`);
  }
}
function invalid_snippet() {
  if (true_default) {
    const error = new Error(`invalid_snippet
Could not \`{@render}\` snippet due to the expression being \`null\` or \`undefined\`. Consider using optional chaining \`{@render snippet?.()}\`
https://svelte.dev/e/invalid_snippet`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/invalid_snippet`);
  }
}
function props_invalid_value(key2) {
  if (true_default) {
    const error = new Error(`props_invalid_value
Cannot do \`bind:${key2}={undefined}\` when \`${key2}\` has a fallback value
https://svelte.dev/e/props_invalid_value`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/props_invalid_value`);
  }
}
function props_rest_readonly(property) {
  if (true_default) {
    const error = new Error(`props_rest_readonly
Rest element properties of \`$props()\` such as \`${property}\` are readonly
https://svelte.dev/e/props_rest_readonly`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/props_rest_readonly`);
  }
}
function rune_outside_svelte(rune) {
  if (true_default) {
    const error = new Error(`rune_outside_svelte
The \`${rune}\` rune is only available inside \`.svelte\` and \`.svelte.js/ts\` files
https://svelte.dev/e/rune_outside_svelte`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/rune_outside_svelte`);
  }
}
function state_descriptors_fixed() {
  if (true_default) {
    const error = new Error(`state_descriptors_fixed
Property descriptors defined on \`$state\` objects must contain \`value\` and always be \`enumerable\`, \`configurable\` and \`writable\`.
https://svelte.dev/e/state_descriptors_fixed`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/state_descriptors_fixed`);
  }
}
function state_prototype_fixed() {
  if (true_default) {
    const error = new Error(`state_prototype_fixed
Cannot set prototype of \`$state\` object
https://svelte.dev/e/state_prototype_fixed`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/state_prototype_fixed`);
  }
}
function state_unsafe_mutation() {
  if (true_default) {
    const error = new Error(`state_unsafe_mutation
Updating state inside \`$derived(...)\`, \`$inspect(...)\` or a template expression is forbidden. If the value should not be reactive, declare it without \`$state\`
https://svelte.dev/e/state_unsafe_mutation`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/state_unsafe_mutation`);
  }
}
function svelte_boundary_reset_onerror() {
  if (true_default) {
    const error = new Error(`svelte_boundary_reset_onerror
A \`<svelte:boundary>\` \`reset\` function cannot be called while an error is still being handled
https://svelte.dev/e/svelte_boundary_reset_onerror`);
    error.name = "Svelte error";
    throw error;
  } else {
    throw new Error(`https://svelte.dev/e/svelte_boundary_reset_onerror`);
  }
}
var init_errors2 = __esm({
  "node_modules/svelte/src/internal/client/errors.js"() {
    init_esm_env();
    init_errors();
  }
});

// node_modules/svelte/src/internal/client/warnings.js
function assignment_value_stale(property, location) {
  if (true_default) {
    console.warn(`%c[svelte] assignment_value_stale
%cAssignment to \`${property}\` property (${location}) will evaluate to the right-hand side, not the value of \`${property}\` following the assignment. This may result in unexpected behaviour.
https://svelte.dev/e/assignment_value_stale`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/assignment_value_stale`);
  }
}
function await_waterfall(name, location) {
  if (true_default) {
    console.warn(`%c[svelte] await_waterfall
%cAn async derived, \`${name}\` (${location}) was not read immediately after it resolved. This often indicates an unnecessary waterfall, which can slow down your app
https://svelte.dev/e/await_waterfall`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/await_waterfall`);
  }
}
function binding_property_non_reactive(binding, location) {
  if (true_default) {
    console.warn(
      `%c[svelte] binding_property_non_reactive
%c${location ? `\`${binding}\` (${location}) is binding to a non-reactive property` : `\`${binding}\` is binding to a non-reactive property`}
https://svelte.dev/e/binding_property_non_reactive`,
      bold,
      normal
    );
  } else {
    console.warn(`https://svelte.dev/e/binding_property_non_reactive`);
  }
}
function console_log_state(method) {
  if (true_default) {
    console.warn(`%c[svelte] console_log_state
%cYour \`console.${method}\` contained \`$state\` proxies. Consider using \`$inspect(...)\` or \`$state.snapshot(...)\` instead
https://svelte.dev/e/console_log_state`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/console_log_state`);
  }
}
function event_handler_invalid(handler, suggestion) {
  if (true_default) {
    console.warn(`%c[svelte] event_handler_invalid
%c${handler} should be a function. Did you mean to ${suggestion}?
https://svelte.dev/e/event_handler_invalid`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/event_handler_invalid`);
  }
}
function hydration_attribute_changed(attribute, html3, value) {
  if (true_default) {
    console.warn(`%c[svelte] hydration_attribute_changed
%cThe \`${attribute}\` attribute on \`${html3}\` changed its value between server and client renders. The client value, \`${value}\`, will be ignored in favour of the server value
https://svelte.dev/e/hydration_attribute_changed`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/hydration_attribute_changed`);
  }
}
function hydration_html_changed(location) {
  if (true_default) {
    console.warn(
      `%c[svelte] hydration_html_changed
%c${location ? `The value of an \`{@html ...}\` block ${location} changed between server and client renders. The client value will be ignored in favour of the server value` : "The value of an `{@html ...}` block changed between server and client renders. The client value will be ignored in favour of the server value"}
https://svelte.dev/e/hydration_html_changed`,
      bold,
      normal
    );
  } else {
    console.warn(`https://svelte.dev/e/hydration_html_changed`);
  }
}
function hydration_mismatch(location) {
  if (true_default) {
    console.warn(
      `%c[svelte] hydration_mismatch
%c${location ? `Hydration failed because the initial UI does not match what was rendered on the server. The error occurred near ${location}` : "Hydration failed because the initial UI does not match what was rendered on the server"}
https://svelte.dev/e/hydration_mismatch`,
      bold,
      normal
    );
  } else {
    console.warn(`https://svelte.dev/e/hydration_mismatch`);
  }
}
function lifecycle_double_unmount() {
  if (true_default) {
    console.warn(`%c[svelte] lifecycle_double_unmount
%cTried to unmount a component that was not mounted
https://svelte.dev/e/lifecycle_double_unmount`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/lifecycle_double_unmount`);
  }
}
function ownership_invalid_binding(parent, prop2, child2, owner) {
  if (true_default) {
    console.warn(`%c[svelte] ownership_invalid_binding
%c${parent} passed property \`${prop2}\` to ${child2} with \`bind:\`, but its parent component ${owner} did not declare \`${prop2}\` as a binding. Consider creating a binding between ${owner} and ${parent} (e.g. \`bind:${prop2}={...}\` instead of \`${prop2}={...}\`)
https://svelte.dev/e/ownership_invalid_binding`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/ownership_invalid_binding`);
  }
}
function ownership_invalid_mutation(name, location, prop2, parent) {
  if (true_default) {
    console.warn(`%c[svelte] ownership_invalid_mutation
%cMutating unbound props (\`${name}\`, at ${location}) is strongly discouraged. Consider using \`bind:${prop2}={...}\` in ${parent} (or using a callback) instead
https://svelte.dev/e/ownership_invalid_mutation`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/ownership_invalid_mutation`);
  }
}
function select_multiple_invalid_value() {
  if (true_default) {
    console.warn(`%c[svelte] select_multiple_invalid_value
%cThe \`value\` property of a \`<select multiple>\` element should be an array, but it received a non-array value. The selection will be kept as is.
https://svelte.dev/e/select_multiple_invalid_value`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/select_multiple_invalid_value`);
  }
}
function state_proxy_equality_mismatch(operator) {
  if (true_default) {
    console.warn(`%c[svelte] state_proxy_equality_mismatch
%cReactive \`$state(...)\` proxies and the values they proxy have different identities. Because of this, comparisons with \`${operator}\` will produce unexpected results
https://svelte.dev/e/state_proxy_equality_mismatch`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/state_proxy_equality_mismatch`);
  }
}
function state_proxy_unmount() {
  if (true_default) {
    console.warn(`%c[svelte] state_proxy_unmount
%cTried to unmount a state proxy, rather than a component
https://svelte.dev/e/state_proxy_unmount`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/state_proxy_unmount`);
  }
}
function svelte_boundary_reset_noop() {
  if (true_default) {
    console.warn(`%c[svelte] svelte_boundary_reset_noop
%cA \`<svelte:boundary>\` \`reset\` function only resets the boundary the first time it is called
https://svelte.dev/e/svelte_boundary_reset_noop`, bold, normal);
  } else {
    console.warn(`https://svelte.dev/e/svelte_boundary_reset_noop`);
  }
}
var bold, normal;
var init_warnings = __esm({
  "node_modules/svelte/src/internal/client/warnings.js"() {
    init_esm_env();
    bold = "font-weight: bold";
    normal = "font-weight: normal";
  }
});

// node_modules/svelte/src/internal/client/dom/hydration.js
function set_hydrating(value) {
  hydrating = value;
}
function set_hydrate_node(node) {
  if (node === null) {
    hydration_mismatch();
    throw HYDRATION_ERROR;
  }
  return hydrate_node = node;
}
function hydrate_next() {
  return set_hydrate_node(
    /** @type {TemplateNode} */
    get_next_sibling(hydrate_node)
  );
}
function reset(node) {
  if (!hydrating) return;
  if (get_next_sibling(hydrate_node) !== null) {
    hydration_mismatch();
    throw HYDRATION_ERROR;
  }
  hydrate_node = node;
}
function hydrate_template(template) {
  if (hydrating) {
    hydrate_node = template.content;
  }
}
function next(count = 1) {
  if (hydrating) {
    var i = count;
    var node = hydrate_node;
    while (i--) {
      node = /** @type {TemplateNode} */
      get_next_sibling(node);
    }
    hydrate_node = node;
  }
}
function skip_nodes(remove = true) {
  var depth = 0;
  var node = hydrate_node;
  while (true) {
    if (node.nodeType === COMMENT_NODE) {
      var data = (
        /** @type {Comment} */
        node.data
      );
      if (data === HYDRATION_END) {
        if (depth === 0) return node;
        depth -= 1;
      } else if (data === HYDRATION_START || data === HYDRATION_START_ELSE) {
        depth += 1;
      }
    }
    var next2 = (
      /** @type {TemplateNode} */
      get_next_sibling(node)
    );
    if (remove) node.remove();
    node = next2;
  }
}
function read_hydration_instruction(node) {
  if (!node || node.nodeType !== COMMENT_NODE) {
    hydration_mismatch();
    throw HYDRATION_ERROR;
  }
  return (
    /** @type {Comment} */
    node.data
  );
}
var hydrating, hydrate_node;
var init_hydration = __esm({
  "node_modules/svelte/src/internal/client/dom/hydration.js"() {
    init_constants2();
    init_constants();
    init_warnings();
    init_operations();
    hydrating = false;
  }
});

// node_modules/svelte/src/internal/client/reactivity/equality.js
function equals(value) {
  return value === this.v;
}
function safe_not_equal(a, b) {
  return a != a ? b == b : a !== b || a !== null && typeof a === "object" || typeof a === "function";
}
function safe_equals(value) {
  return !safe_not_equal(value, this.v);
}
var init_equality = __esm({
  "node_modules/svelte/src/internal/client/reactivity/equality.js"() {
  }
});

// node_modules/svelte/src/internal/flags/index.js
var async_mode_flag, legacy_mode_flag, tracing_mode_flag;
var init_flags = __esm({
  "node_modules/svelte/src/internal/flags/index.js"() {
    async_mode_flag = false;
    legacy_mode_flag = false;
    tracing_mode_flag = false;
  }
});

// node_modules/svelte/src/internal/shared/warnings.js
function dynamic_void_element_content(tag2) {
  if (true_default) {
    console.warn(`%c[svelte] dynamic_void_element_content
%c\`<svelte:element this="${tag2}">\` is a void element \u2014 it cannot have content
https://svelte.dev/e/dynamic_void_element_content`, bold2, normal2);
  } else {
    console.warn(`https://svelte.dev/e/dynamic_void_element_content`);
  }
}
function state_snapshot_uncloneable(properties) {
  if (true_default) {
    console.warn(
      `%c[svelte] state_snapshot_uncloneable
%c${properties ? `The following properties cannot be cloned with \`$state.snapshot\` \u2014 the return value contains the originals:

${properties}` : "Value cannot be cloned with `$state.snapshot` \u2014 the original value was returned"}
https://svelte.dev/e/state_snapshot_uncloneable`,
      bold2,
      normal2
    );
  } else {
    console.warn(`https://svelte.dev/e/state_snapshot_uncloneable`);
  }
}
var bold2, normal2;
var init_warnings2 = __esm({
  "node_modules/svelte/src/internal/shared/warnings.js"() {
    init_esm_env();
    bold2 = "font-weight: bold";
    normal2 = "font-weight: normal";
  }
});

// node_modules/svelte/src/internal/shared/clone.js
function snapshot(value, skip_warning = false, no_tojson = false) {
  if (true_default && !skip_warning) {
    const paths = [];
    const copy = clone(value, /* @__PURE__ */ new Map(), "", paths, null, no_tojson);
    if (paths.length === 1 && paths[0] === "") {
      state_snapshot_uncloneable();
    } else if (paths.length > 0) {
      const slice = paths.length > 10 ? paths.slice(0, 7) : paths.slice(0, 10);
      const excess = paths.length - slice.length;
      let uncloned = slice.map((path) => `- <value>${path}`).join("\n");
      if (excess > 0) uncloned += `
- ...and ${excess} more`;
      state_snapshot_uncloneable(uncloned);
    }
    return copy;
  }
  return clone(value, /* @__PURE__ */ new Map(), "", empty, null, no_tojson);
}
function clone(value, cloned, path, paths, original = null, no_tojson = false) {
  if (typeof value === "object" && value !== null) {
    var unwrapped = cloned.get(value);
    if (unwrapped !== void 0) return unwrapped;
    if (value instanceof Map) return (
      /** @type {Snapshot<T>} */
      new Map(value)
    );
    if (value instanceof Set) return (
      /** @type {Snapshot<T>} */
      new Set(value)
    );
    if (is_array(value)) {
      var copy = (
        /** @type {Snapshot<any>} */
        Array(value.length)
      );
      cloned.set(value, copy);
      if (original !== null) {
        cloned.set(original, copy);
      }
      for (var i = 0; i < value.length; i += 1) {
        var element2 = value[i];
        if (i in value) {
          copy[i] = clone(element2, cloned, true_default ? `${path}[${i}]` : path, paths, null, no_tojson);
        }
      }
      return copy;
    }
    if (get_prototype_of(value) === object_prototype) {
      copy = {};
      cloned.set(value, copy);
      if (original !== null) {
        cloned.set(original, copy);
      }
      for (var key2 in value) {
        copy[key2] = clone(
          // @ts-expect-error
          value[key2],
          cloned,
          true_default ? `${path}.${key2}` : path,
          paths,
          null,
          no_tojson
        );
      }
      return copy;
    }
    if (value instanceof Date) {
      return (
        /** @type {Snapshot<T>} */
        structuredClone(value)
      );
    }
    if (typeof /** @type {T & { toJSON?: any } } */
    value.toJSON === "function" && !no_tojson) {
      return clone(
        /** @type {T & { toJSON(): any } } */
        value.toJSON(),
        cloned,
        true_default ? `${path}.toJSON()` : path,
        paths,
        // Associate the instance with the toJSON clone
        value
      );
    }
  }
  if (value instanceof EventTarget) {
    return (
      /** @type {Snapshot<T>} */
      value
    );
  }
  try {
    return (
      /** @type {Snapshot<T>} */
      structuredClone(value)
    );
  } catch (e) {
    if (true_default) {
      paths.push(path);
    }
    return (
      /** @type {Snapshot<T>} */
      value
    );
  }
}
var empty;
var init_clone = __esm({
  "node_modules/svelte/src/internal/shared/clone.js"() {
    init_esm_env();
    init_warnings2();
    init_utils();
    empty = [];
  }
});

// node_modules/svelte/src/internal/client/dev/tracing.js
function log_entry(signal, entry) {
  const value = signal.v;
  if (value === UNINITIALIZED) {
    return;
  }
  const type = get_type(signal);
  const current_reaction = (
    /** @type {Reaction} */
    active_reaction
  );
  const dirty = signal.wv > current_reaction.wv || current_reaction.wv === 0;
  const style = dirty ? "color: CornflowerBlue; font-weight: bold" : "color: grey; font-weight: normal";
  console.groupCollapsed(
    signal.label ? `%c${type}%c ${signal.label}` : `%c${type}%c`,
    style,
    dirty ? "font-weight: normal" : style,
    typeof value === "object" && value !== null && STATE_SYMBOL in value ? snapshot(value, true) : value
  );
  if (type === "$derived") {
    const deps = new Set(
      /** @type {Derived} */
      signal.deps
    );
    for (const dep of deps) {
      log_entry(dep);
    }
  }
  if (signal.created) {
    console.log(signal.created);
  }
  if (dirty && signal.updated) {
    for (const updated of signal.updated.values()) {
      if (updated.error) {
        console.log(updated.error);
      }
    }
  }
  if (entry) {
    for (var trace2 of entry.traces) {
      console.log(trace2);
    }
  }
  console.groupEnd();
}
function get_type(signal) {
  if ((signal.f & (DERIVED | ASYNC)) !== 0) return "$derived";
  return signal.label?.startsWith("$") ? "store" : "$state";
}
function trace(label, fn) {
  var previously_tracing_expressions = tracing_expressions;
  try {
    tracing_expressions = { entries: /* @__PURE__ */ new Map(), reaction: active_reaction };
    var start = performance.now();
    var value = fn();
    var time = (performance.now() - start).toFixed(2);
    var prefix = untrack(label);
    if (!effect_tracking()) {
      console.log(`${prefix} %cran outside of an effect (${time}ms)`, "color: grey");
    } else if (tracing_expressions.entries.size === 0) {
      console.log(`${prefix} %cno reactive dependencies (${time}ms)`, "color: grey");
    } else {
      console.group(`${prefix} %c(${time}ms)`, "color: grey");
      var entries = tracing_expressions.entries;
      untrack(() => {
        for (const [signal, traces] of entries) {
          log_entry(signal, traces);
        }
      });
      tracing_expressions = null;
      console.groupEnd();
    }
    return value;
  } finally {
    tracing_expressions = previously_tracing_expressions;
  }
}
function tag(source2, label) {
  source2.label = label;
  tag_proxy(source2.v, label);
  return source2;
}
function tag_proxy(value, label) {
  value?.[PROXY_PATH_SYMBOL]?.(label);
  return value;
}
var tracing_expressions;
var init_tracing = __esm({
  "node_modules/svelte/src/internal/client/dev/tracing.js"() {
    init_constants();
    init_clone();
    init_constants2();
    init_effects();
    init_runtime();
    tracing_expressions = null;
  }
});

// node_modules/svelte/src/internal/shared/dev.js
function get_error(label) {
  const error = new Error();
  const stack2 = get_stack();
  if (stack2.length === 0) {
    return null;
  }
  stack2.unshift("\n");
  define_property(error, "stack", {
    value: stack2.join("\n")
  });
  define_property(error, "name", {
    value: label
  });
  return (
    /** @type {Error & { stack: string }} */
    error
  );
}
function get_stack() {
  const limit = Error.stackTraceLimit;
  Error.stackTraceLimit = Infinity;
  const stack2 = new Error().stack;
  Error.stackTraceLimit = limit;
  if (!stack2) return [];
  const lines = stack2.split("\n");
  const new_lines = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const posixified = line.replaceAll("\\", "/");
    if (line.trim() === "Error") {
      continue;
    }
    if (line.includes("validate_each_keys")) {
      return [];
    }
    if (posixified.includes("svelte/src/internal") || posixified.includes("node_modules/.vite")) {
      continue;
    }
    new_lines.push(line);
  }
  return new_lines;
}
var init_dev = __esm({
  "node_modules/svelte/src/internal/shared/dev.js"() {
    init_utils();
  }
});

// node_modules/svelte/src/internal/client/context.js
function set_component_context(context2) {
  component_context = context2;
}
function set_dev_stack(stack2) {
  dev_stack = stack2;
}
function add_svelte_meta(callback, type, component2, line, column, additional) {
  const parent = dev_stack;
  dev_stack = {
    type,
    file: component2[FILENAME],
    line,
    column,
    parent,
    ...additional
  };
  try {
    return callback();
  } finally {
    dev_stack = parent;
  }
}
function set_dev_current_component_function(fn) {
  dev_current_component_function = fn;
}
function push(props, runes = false, fn) {
  component_context = {
    p: component_context,
    i: false,
    c: null,
    e: null,
    s: props,
    x: null,
    l: legacy_mode_flag && !runes ? { s: null, u: null, $: [] } : null
  };
  if (true_default) {
    component_context.function = fn;
    dev_current_component_function = fn;
  }
}
function pop(component2) {
  var context2 = (
    /** @type {ComponentContext} */
    component_context
  );
  var effects = context2.e;
  if (effects !== null) {
    context2.e = null;
    for (var fn of effects) {
      create_user_effect(fn);
    }
  }
  if (component2 !== void 0) {
    context2.x = component2;
  }
  context2.i = true;
  component_context = context2.p;
  if (true_default) {
    dev_current_component_function = component_context?.function ?? null;
  }
  return component2 ?? /** @type {T} */
  {};
}
function is_runes() {
  return !legacy_mode_flag || component_context !== null && component_context.l === null;
}
var component_context, dev_stack, dev_current_component_function;
var init_context = __esm({
  "node_modules/svelte/src/internal/client/context.js"() {
    init_esm_env();
    init_errors2();
    init_runtime();
    init_effects();
    init_flags();
    init_constants();
    init_constants2();
    component_context = null;
    dev_stack = null;
    dev_current_component_function = null;
  }
});

// node_modules/svelte/src/internal/client/dom/task.js
function run_micro_tasks() {
  var tasks = micro_tasks;
  micro_tasks = [];
  run_all(tasks);
}
function queue_micro_task(fn) {
  if (micro_tasks.length === 0 && !is_flushing_sync) {
    var tasks = micro_tasks;
    queueMicrotask(() => {
      if (tasks === micro_tasks) run_micro_tasks();
    });
  }
  micro_tasks.push(fn);
}
function flush_tasks() {
  while (micro_tasks.length > 0) {
    run_micro_tasks();
  }
}
var micro_tasks;
var init_task = __esm({
  "node_modules/svelte/src/internal/client/dom/task.js"() {
    init_utils();
    init_batch();
    micro_tasks = [];
  }
});

// node_modules/svelte/src/internal/client/error-handling.js
function handle_error(error) {
  var effect2 = active_effect;
  if (effect2 === null) {
    active_reaction.f |= ERROR_VALUE;
    return error;
  }
  if (true_default && error instanceof Error && !adjustments.has(error)) {
    adjustments.set(error, get_adjustments(error, effect2));
  }
  if ((effect2.f & EFFECT_RAN) === 0) {
    if ((effect2.f & BOUNDARY_EFFECT) === 0) {
      if (true_default && !effect2.parent && error instanceof Error) {
        apply_adjustments(error);
      }
      throw error;
    }
    effect2.b.error(error);
  } else {
    invoke_error_boundary(error, effect2);
  }
}
function invoke_error_boundary(error, effect2) {
  while (effect2 !== null) {
    if ((effect2.f & BOUNDARY_EFFECT) !== 0) {
      try {
        effect2.b.error(error);
        return;
      } catch (e) {
        error = e;
      }
    }
    effect2 = effect2.parent;
  }
  if (true_default && error instanceof Error) {
    apply_adjustments(error);
  }
  throw error;
}
function get_adjustments(error, effect2) {
  const message_descriptor = get_descriptor(error, "message");
  if (message_descriptor && !message_descriptor.configurable) return;
  var indent = is_firefox ? "  " : "	";
  var component_stack = `
${indent}in ${effect2.fn?.name || "<unknown>"}`;
  var context2 = effect2.ctx;
  while (context2 !== null) {
    component_stack += `
${indent}in ${context2.function?.[FILENAME].split("/").pop()}`;
    context2 = context2.p;
  }
  return {
    message: error.message + `
${component_stack}
`,
    stack: error.stack?.split("\n").filter((line) => !line.includes("svelte/src/internal")).join("\n")
  };
}
function apply_adjustments(error) {
  const adjusted = adjustments.get(error);
  if (adjusted) {
    define_property(error, "message", {
      value: adjusted.message
    });
    define_property(error, "stack", {
      value: adjusted.stack
    });
  }
}
var adjustments;
var init_error_handling = __esm({
  "node_modules/svelte/src/internal/client/error-handling.js"() {
    init_esm_env();
    init_constants();
    init_operations();
    init_constants2();
    init_utils();
    init_runtime();
    adjustments = /* @__PURE__ */ new WeakMap();
  }
});

// node_modules/svelte/src/internal/client/reactivity/batch.js
function flushSync(fn) {
  var was_flushing_sync = is_flushing_sync;
  is_flushing_sync = true;
  try {
    var result;
    if (fn) {
      if (current_batch !== null) {
        flush_effects();
      }
      result = fn();
    }
    while (true) {
      flush_tasks();
      if (queued_root_effects.length === 0) {
        current_batch?.flush();
        if (queued_root_effects.length === 0) {
          last_scheduled_effect = null;
          return (
            /** @type {T} */
            result
          );
        }
      }
      flush_effects();
    }
  } finally {
    is_flushing_sync = was_flushing_sync;
  }
}
function flush_effects() {
  var was_updating_effect = is_updating_effect;
  is_flushing = true;
  var source_stacks = true_default ? /* @__PURE__ */ new Set() : null;
  try {
    var flush_count = 0;
    set_is_updating_effect(true);
    while (queued_root_effects.length > 0) {
      var batch = Batch.ensure();
      if (flush_count++ > 1e3) {
        if (true_default) {
          var updates = /* @__PURE__ */ new Map();
          for (const source2 of batch.current.keys()) {
            for (const [stack2, update2] of source2.updated ?? []) {
              var entry = updates.get(stack2);
              if (!entry) {
                entry = { error: update2.error, count: 0 };
                updates.set(stack2, entry);
              }
              entry.count += update2.count;
            }
          }
          for (const update2 of updates.values()) {
            if (update2.error) {
              console.error(update2.error);
            }
          }
        }
        infinite_loop_guard();
      }
      batch.process(queued_root_effects);
      old_values.clear();
      if (true_default) {
        for (const source2 of batch.current.keys()) {
          source_stacks.add(source2);
        }
      }
    }
  } finally {
    is_flushing = false;
    set_is_updating_effect(was_updating_effect);
    last_scheduled_effect = null;
    if (true_default) {
      for (
        const source2 of
        /** @type {Set<Source>} */
        source_stacks
      ) {
        source2.updated = null;
      }
    }
  }
}
function infinite_loop_guard() {
  try {
    effect_update_depth_exceeded();
  } catch (error) {
    if (true_default) {
      define_property(error, "stack", { value: "" });
    }
    invoke_error_boundary(error, last_scheduled_effect);
  }
}
function flush_queued_effects(effects) {
  var length = effects.length;
  if (length === 0) return;
  var i = 0;
  while (i < length) {
    var effect2 = effects[i++];
    if ((effect2.f & (DESTROYED | INERT)) === 0 && is_dirty(effect2)) {
      eager_block_effects = /* @__PURE__ */ new Set();
      update_effect(effect2);
      if (effect2.deps === null && effect2.first === null && effect2.nodes_start === null) {
        if (effect2.teardown === null && effect2.ac === null) {
          unlink_effect(effect2);
        } else {
          effect2.fn = null;
        }
      }
      if (eager_block_effects?.size > 0) {
        old_values.clear();
        for (const e of eager_block_effects) {
          if ((e.f & (DESTROYED | INERT)) !== 0) continue;
          const ordered_effects = [e];
          let ancestor = e.parent;
          while (ancestor !== null) {
            if (eager_block_effects.has(ancestor)) {
              eager_block_effects.delete(ancestor);
              ordered_effects.push(ancestor);
            }
            ancestor = ancestor.parent;
          }
          for (let j = ordered_effects.length - 1; j >= 0; j--) {
            const e2 = ordered_effects[j];
            if ((e2.f & (DESTROYED | INERT)) !== 0) continue;
            update_effect(e2);
          }
        }
        eager_block_effects.clear();
      }
    }
  }
  eager_block_effects = null;
}
function mark_effects(value, sources, marked, checked) {
  if (marked.has(value)) return;
  marked.add(value);
  if (value.reactions !== null) {
    for (const reaction of value.reactions) {
      const flags2 = reaction.f;
      if ((flags2 & DERIVED) !== 0) {
        mark_effects(
          /** @type {Derived} */
          reaction,
          sources,
          marked,
          checked
        );
      } else if ((flags2 & (ASYNC | BLOCK_EFFECT)) !== 0 && (flags2 & DIRTY) === 0 && depends_on(reaction, sources, checked)) {
        set_signal_status(reaction, DIRTY);
        schedule_effect(
          /** @type {Effect} */
          reaction
        );
      }
    }
  }
}
function depends_on(reaction, sources, checked) {
  const depends = checked.get(reaction);
  if (depends !== void 0) return depends;
  if (reaction.deps !== null) {
    for (const dep of reaction.deps) {
      if (sources.includes(dep)) {
        return true;
      }
      if ((dep.f & DERIVED) !== 0 && depends_on(
        /** @type {Derived} */
        dep,
        sources,
        checked
      )) {
        checked.set(
          /** @type {Derived} */
          dep,
          true
        );
        return true;
      }
    }
  }
  checked.set(reaction, false);
  return false;
}
function schedule_effect(signal) {
  var effect2 = last_scheduled_effect = signal;
  while (effect2.parent !== null) {
    effect2 = effect2.parent;
    var flags2 = effect2.f;
    if (is_flushing && effect2 === active_effect && (flags2 & BLOCK_EFFECT) !== 0 && (flags2 & HEAD_EFFECT) === 0) {
      return;
    }
    if ((flags2 & (ROOT_EFFECT | BRANCH_EFFECT)) !== 0) {
      if ((flags2 & CLEAN) === 0) return;
      effect2.f ^= CLEAN;
    }
  }
  queued_root_effects.push(effect2);
}
function eager_flush() {
  try {
    flushSync(() => {
      for (const version of eager_versions) {
        update(version);
      }
    });
  } finally {
    eager_versions = [];
  }
}
function eager(fn) {
  var version = source(0);
  var initial = true;
  var value = (
    /** @type {T} */
    void 0
  );
  get(version);
  eager_effect(() => {
    if (initial) {
      var previous_batch_values = batch_values;
      try {
        batch_values = null;
        value = fn();
      } finally {
        batch_values = previous_batch_values;
      }
      return;
    }
    if (eager_versions.length === 0) {
      queue_micro_task(eager_flush);
    }
    eager_versions.push(version);
  });
  initial = false;
  return value;
}
var batches, current_batch, previous_batch, batch_values, queued_root_effects, last_scheduled_effect, is_flushing, is_flushing_sync, Batch, eager_block_effects, eager_versions;
var init_batch = __esm({
  "node_modules/svelte/src/internal/client/reactivity/batch.js"() {
    init_constants2();
    init_flags();
    init_utils();
    init_runtime();
    init_errors2();
    init_task();
    init_esm_env();
    init_error_handling();
    init_sources();
    init_effects();
    batches = /* @__PURE__ */ new Set();
    current_batch = null;
    previous_batch = null;
    batch_values = null;
    queued_root_effects = [];
    last_scheduled_effect = null;
    is_flushing = false;
    is_flushing_sync = false;
    Batch = class _Batch {
      committed = false;
      /**
       * The current values of any sources that are updated in this batch
       * They keys of this map are identical to `this.#previous`
       * @type {Map<Source, any>}
       */
      current = /* @__PURE__ */ new Map();
      /**
       * The values of any sources that are updated in this batch _before_ those updates took place.
       * They keys of this map are identical to `this.#current`
       * @type {Map<Source, any>}
       */
      previous = /* @__PURE__ */ new Map();
      /**
       * When the batch is committed (and the DOM is updated), we need to remove old branches
       * and append new ones by calling the functions added inside (if/each/key/etc) blocks
       * @type {Set<() => void>}
       */
      #commit_callbacks = /* @__PURE__ */ new Set();
      /**
       * If a fork is discarded, we need to destroy any effects that are no longer needed
       * @type {Set<(batch: Batch) => void>}
       */
      #discard_callbacks = /* @__PURE__ */ new Set();
      /**
       * The number of async effects that are currently in flight
       */
      #pending = 0;
      /**
       * The number of async effects that are currently in flight, _not_ inside a pending boundary
       */
      #blocking_pending = 0;
      /**
       * A deferred that resolves when the batch is committed, used with `settled()`
       * TODO replace with Promise.withResolvers once supported widely enough
       * @type {{ promise: Promise<void>, resolve: (value?: any) => void, reject: (reason: unknown) => void } | null}
       */
      #deferred = null;
      /**
       * Deferred effects (which run after async work has completed) that are DIRTY
       * @type {Effect[]}
       */
      #dirty_effects = [];
      /**
       * Deferred effects that are MAYBE_DIRTY
       * @type {Effect[]}
       */
      #maybe_dirty_effects = [];
      /**
       * A set of branches that still exist, but will be destroyed when this batch
       * is committed — we skip over these during `process`
       * @type {Set<Effect>}
       */
      skipped_effects = /* @__PURE__ */ new Set();
      is_fork = false;
      is_deferred() {
        return this.is_fork || this.#blocking_pending > 0;
      }
      /**
       *
       * @param {Effect[]} root_effects
       */
      process(root_effects) {
        queued_root_effects = [];
        previous_batch = null;
        this.apply();
        var target = {
          parent: null,
          effect: null,
          effects: [],
          render_effects: [],
          block_effects: []
        };
        for (const root of root_effects) {
          this.#traverse_effect_tree(root, target);
        }
        if (!this.is_fork) {
          this.#resolve();
        }
        if (this.is_deferred()) {
          this.#defer_effects(target.effects);
          this.#defer_effects(target.render_effects);
          this.#defer_effects(target.block_effects);
        } else {
          previous_batch = this;
          current_batch = null;
          flush_queued_effects(target.render_effects);
          flush_queued_effects(target.effects);
          previous_batch = null;
          this.#deferred?.resolve();
        }
        batch_values = null;
      }
      /**
       * Traverse the effect tree, executing effects or stashing
       * them for later execution as appropriate
       * @param {Effect} root
       * @param {EffectTarget} target
       */
      #traverse_effect_tree(root, target) {
        root.f ^= CLEAN;
        var effect2 = root.first;
        while (effect2 !== null) {
          var flags2 = effect2.f;
          var is_branch = (flags2 & (BRANCH_EFFECT | ROOT_EFFECT)) !== 0;
          var is_skippable_branch = is_branch && (flags2 & CLEAN) !== 0;
          var skip = is_skippable_branch || (flags2 & INERT) !== 0 || this.skipped_effects.has(effect2);
          if ((effect2.f & BOUNDARY_EFFECT) !== 0 && effect2.b?.is_pending()) {
            target = {
              parent: target,
              effect: effect2,
              effects: [],
              render_effects: [],
              block_effects: []
            };
          }
          if (!skip && effect2.fn !== null) {
            if (is_branch) {
              effect2.f ^= CLEAN;
            } else if ((flags2 & EFFECT) !== 0) {
              target.effects.push(effect2);
            } else if (async_mode_flag && (flags2 & (RENDER_EFFECT | MANAGED_EFFECT)) !== 0) {
              target.render_effects.push(effect2);
            } else if (is_dirty(effect2)) {
              if ((effect2.f & BLOCK_EFFECT) !== 0) target.block_effects.push(effect2);
              update_effect(effect2);
            }
            var child2 = effect2.first;
            if (child2 !== null) {
              effect2 = child2;
              continue;
            }
          }
          var parent = effect2.parent;
          effect2 = effect2.next;
          while (effect2 === null && parent !== null) {
            if (parent === target.effect) {
              this.#defer_effects(target.effects);
              this.#defer_effects(target.render_effects);
              this.#defer_effects(target.block_effects);
              target = /** @type {EffectTarget} */
              target.parent;
            }
            effect2 = parent.next;
            parent = parent.parent;
          }
        }
      }
      /**
       * @param {Effect[]} effects
       */
      #defer_effects(effects) {
        for (const e of effects) {
          const target = (e.f & DIRTY) !== 0 ? this.#dirty_effects : this.#maybe_dirty_effects;
          target.push(e);
          this.#clear_marked(e.deps);
          set_signal_status(e, CLEAN);
        }
      }
      /**
       * @param {Value[] | null} deps
       */
      #clear_marked(deps) {
        if (deps === null) return;
        for (const dep of deps) {
          if ((dep.f & DERIVED) === 0 || (dep.f & WAS_MARKED) === 0) {
            continue;
          }
          dep.f ^= WAS_MARKED;
          this.#clear_marked(
            /** @type {Derived} */
            dep.deps
          );
        }
      }
      /**
       * Associate a change to a given source with the current
       * batch, noting its previous and current values
       * @param {Source} source
       * @param {any} value
       */
      capture(source2, value) {
        if (!this.previous.has(source2)) {
          this.previous.set(source2, value);
        }
        if ((source2.f & ERROR_VALUE) === 0) {
          this.current.set(source2, source2.v);
          batch_values?.set(source2, source2.v);
        }
      }
      activate() {
        current_batch = this;
        this.apply();
      }
      deactivate() {
        if (current_batch !== this) return;
        current_batch = null;
        batch_values = null;
      }
      flush() {
        this.activate();
        if (queued_root_effects.length > 0) {
          flush_effects();
          if (current_batch !== null && current_batch !== this) {
            return;
          }
        } else if (this.#pending === 0) {
          this.process([]);
        }
        this.deactivate();
      }
      discard() {
        for (const fn of this.#discard_callbacks) fn(this);
        this.#discard_callbacks.clear();
      }
      #resolve() {
        if (this.#blocking_pending === 0) {
          for (const fn of this.#commit_callbacks) fn();
          this.#commit_callbacks.clear();
        }
        if (this.#pending === 0) {
          this.#commit();
        }
      }
      #commit() {
        if (batches.size > 1) {
          this.previous.clear();
          var previous_batch_values = batch_values;
          var is_earlier = true;
          var dummy_target = {
            parent: null,
            effect: null,
            effects: [],
            render_effects: [],
            block_effects: []
          };
          for (const batch of batches) {
            if (batch === this) {
              is_earlier = false;
              continue;
            }
            const sources = [];
            for (const [source2, value] of this.current) {
              if (batch.current.has(source2)) {
                if (is_earlier && value !== batch.current.get(source2)) {
                  batch.current.set(source2, value);
                } else {
                  continue;
                }
              }
              sources.push(source2);
            }
            if (sources.length === 0) {
              continue;
            }
            const others = [...batch.current.keys()].filter((s) => !this.current.has(s));
            if (others.length > 0) {
              var prev_queued_root_effects = queued_root_effects;
              queued_root_effects = [];
              const marked = /* @__PURE__ */ new Set();
              const checked = /* @__PURE__ */ new Map();
              for (const source2 of sources) {
                mark_effects(source2, others, marked, checked);
              }
              if (queued_root_effects.length > 0) {
                current_batch = batch;
                batch.apply();
                for (const root of queued_root_effects) {
                  batch.#traverse_effect_tree(root, dummy_target);
                }
                batch.deactivate();
              }
              queued_root_effects = prev_queued_root_effects;
            }
          }
          current_batch = null;
          batch_values = previous_batch_values;
        }
        this.committed = true;
        batches.delete(this);
      }
      /**
       *
       * @param {boolean} blocking
       */
      increment(blocking) {
        this.#pending += 1;
        if (blocking) this.#blocking_pending += 1;
      }
      /**
       *
       * @param {boolean} blocking
       */
      decrement(blocking) {
        this.#pending -= 1;
        if (blocking) this.#blocking_pending -= 1;
        this.revive();
      }
      revive() {
        for (const e of this.#dirty_effects) {
          set_signal_status(e, DIRTY);
          schedule_effect(e);
        }
        for (const e of this.#maybe_dirty_effects) {
          set_signal_status(e, MAYBE_DIRTY);
          schedule_effect(e);
        }
        this.#dirty_effects = [];
        this.#maybe_dirty_effects = [];
        this.flush();
      }
      /** @param {() => void} fn */
      oncommit(fn) {
        this.#commit_callbacks.add(fn);
      }
      /** @param {(batch: Batch) => void} fn */
      ondiscard(fn) {
        this.#discard_callbacks.add(fn);
      }
      settled() {
        return (this.#deferred ??= deferred()).promise;
      }
      static ensure() {
        if (current_batch === null) {
          const batch = current_batch = new _Batch();
          batches.add(current_batch);
          if (!is_flushing_sync) {
            _Batch.enqueue(() => {
              if (current_batch !== batch) {
                return;
              }
              batch.flush();
            });
          }
        }
        return current_batch;
      }
      /** @param {() => void} task */
      static enqueue(task) {
        queue_micro_task(task);
      }
      apply() {
        if (!async_mode_flag || !this.is_fork && batches.size === 1) return;
        batch_values = new Map(this.current);
        for (const batch of batches) {
          if (batch === this) continue;
          for (const [source2, previous] of batch.previous) {
            if (!batch_values.has(source2)) {
              batch_values.set(source2, previous);
            }
          }
        }
      }
    };
    eager_block_effects = null;
    eager_versions = [];
  }
});

// node_modules/svelte/src/reactivity/create-subscriber.js
function createSubscriber(start) {
  let subscribers = 0;
  let version = source(0);
  let stop;
  if (true_default) {
    tag(version, "createSubscriber version");
  }
  return () => {
    if (effect_tracking()) {
      get(version);
      render_effect(() => {
        if (subscribers === 0) {
          stop = untrack(() => start(() => increment(version)));
        }
        subscribers += 1;
        return () => {
          queue_micro_task(() => {
            subscribers -= 1;
            if (subscribers === 0) {
              stop?.();
              stop = void 0;
              increment(version);
            }
          });
        };
      });
    }
  };
}
var init_create_subscriber = __esm({
  "node_modules/svelte/src/reactivity/create-subscriber.js"() {
    init_runtime();
    init_effects();
    init_sources();
    init_tracing();
    init_esm_env();
    init_task();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/boundary.js
function boundary(node, props, children) {
  new Boundary(node, props, children);
}
function get_boundary() {
  return (
    /** @type {Boundary} */
    /** @type {Effect} */
    active_effect.b
  );
}
function pending() {
  if (active_effect === null) {
    effect_pending_outside_reaction();
  }
  var boundary2 = active_effect.b;
  if (boundary2 === null) {
    return 0;
  }
  return boundary2.get_effect_pending();
}
var flags, Boundary;
var init_boundary = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/boundary.js"() {
    init_constants2();
    init_constants();
    init_context();
    init_error_handling();
    init_effects();
    init_runtime();
    init_hydration();
    init_task();
    init_errors2();
    init_warnings();
    init_esm_env();
    init_batch();
    init_sources();
    init_tracing();
    init_create_subscriber();
    init_operations();
    flags = EFFECT_TRANSPARENT | EFFECT_PRESERVED | BOUNDARY_EFFECT;
    Boundary = class {
      /** @type {Boundary | null} */
      parent;
      #pending = false;
      /** @type {TemplateNode} */
      #anchor;
      /** @type {TemplateNode | null} */
      #hydrate_open = hydrating ? hydrate_node : null;
      /** @type {BoundaryProps} */
      #props;
      /** @type {((anchor: Node) => void)} */
      #children;
      /** @type {Effect} */
      #effect;
      /** @type {Effect | null} */
      #main_effect = null;
      /** @type {Effect | null} */
      #pending_effect = null;
      /** @type {Effect | null} */
      #failed_effect = null;
      /** @type {DocumentFragment | null} */
      #offscreen_fragment = null;
      /** @type {TemplateNode | null} */
      #pending_anchor = null;
      #local_pending_count = 0;
      #pending_count = 0;
      #is_creating_fallback = false;
      /**
       * A source containing the number of pending async deriveds/expressions.
       * Only created if `$effect.pending()` is used inside the boundary,
       * otherwise updating the source results in needless `Batch.ensure()`
       * calls followed by no-op flushes
       * @type {Source<number> | null}
       */
      #effect_pending = null;
      #effect_pending_subscriber = createSubscriber(() => {
        this.#effect_pending = source(this.#local_pending_count);
        if (true_default) {
          tag(this.#effect_pending, "$effect.pending()");
        }
        return () => {
          this.#effect_pending = null;
        };
      });
      /**
       * @param {TemplateNode} node
       * @param {BoundaryProps} props
       * @param {((anchor: Node) => void)} children
       */
      constructor(node, props, children) {
        this.#anchor = node;
        this.#props = props;
        this.#children = children;
        this.parent = /** @type {Effect} */
        active_effect.b;
        this.#pending = !!this.#props.pending;
        this.#effect = block(() => {
          active_effect.b = this;
          if (hydrating) {
            const comment2 = this.#hydrate_open;
            hydrate_next();
            const server_rendered_pending = (
              /** @type {Comment} */
              comment2.nodeType === COMMENT_NODE && /** @type {Comment} */
              comment2.data === HYDRATION_START_ELSE
            );
            if (server_rendered_pending) {
              this.#hydrate_pending_content();
            } else {
              this.#hydrate_resolved_content();
            }
          } else {
            var anchor = this.#get_anchor();
            try {
              this.#main_effect = branch(() => children(anchor));
            } catch (error) {
              this.error(error);
            }
            if (this.#pending_count > 0) {
              this.#show_pending_snippet();
            } else {
              this.#pending = false;
            }
          }
          return () => {
            this.#pending_anchor?.remove();
          };
        }, flags);
        if (hydrating) {
          this.#anchor = hydrate_node;
        }
      }
      #hydrate_resolved_content() {
        try {
          this.#main_effect = branch(() => this.#children(this.#anchor));
        } catch (error) {
          this.error(error);
        }
        this.#pending = false;
      }
      #hydrate_pending_content() {
        const pending3 = this.#props.pending;
        if (!pending3) {
          return;
        }
        this.#pending_effect = branch(() => pending3(this.#anchor));
        Batch.enqueue(() => {
          var anchor = this.#get_anchor();
          this.#main_effect = this.#run(() => {
            Batch.ensure();
            return branch(() => this.#children(anchor));
          });
          if (this.#pending_count > 0) {
            this.#show_pending_snippet();
          } else {
            pause_effect(
              /** @type {Effect} */
              this.#pending_effect,
              () => {
                this.#pending_effect = null;
              }
            );
            this.#pending = false;
          }
        });
      }
      #get_anchor() {
        var anchor = this.#anchor;
        if (this.#pending) {
          this.#pending_anchor = create_text();
          this.#anchor.before(this.#pending_anchor);
          anchor = this.#pending_anchor;
        }
        return anchor;
      }
      /**
       * Returns `true` if the effect exists inside a boundary whose pending snippet is shown
       * @returns {boolean}
       */
      is_pending() {
        return this.#pending || !!this.parent && this.parent.is_pending();
      }
      has_pending_snippet() {
        return !!this.#props.pending;
      }
      /**
       * @param {() => Effect | null} fn
       */
      #run(fn) {
        var previous_effect = active_effect;
        var previous_reaction = active_reaction;
        var previous_ctx = component_context;
        set_active_effect(this.#effect);
        set_active_reaction(this.#effect);
        set_component_context(this.#effect.ctx);
        try {
          return fn();
        } catch (e) {
          handle_error(e);
          return null;
        } finally {
          set_active_effect(previous_effect);
          set_active_reaction(previous_reaction);
          set_component_context(previous_ctx);
        }
      }
      #show_pending_snippet() {
        const pending3 = (
          /** @type {(anchor: Node) => void} */
          this.#props.pending
        );
        if (this.#main_effect !== null) {
          this.#offscreen_fragment = document.createDocumentFragment();
          this.#offscreen_fragment.append(
            /** @type {TemplateNode} */
            this.#pending_anchor
          );
          move_effect(this.#main_effect, this.#offscreen_fragment);
        }
        if (this.#pending_effect === null) {
          this.#pending_effect = branch(() => pending3(this.#anchor));
        }
      }
      /**
       * Updates the pending count associated with the currently visible pending snippet,
       * if any, such that we can replace the snippet with content once work is done
       * @param {1 | -1} d
       */
      #update_pending_count(d) {
        if (!this.has_pending_snippet()) {
          if (this.parent) {
            this.parent.#update_pending_count(d);
          }
          return;
        }
        this.#pending_count += d;
        if (this.#pending_count === 0) {
          this.#pending = false;
          if (this.#pending_effect) {
            pause_effect(this.#pending_effect, () => {
              this.#pending_effect = null;
            });
          }
          if (this.#offscreen_fragment) {
            this.#anchor.before(this.#offscreen_fragment);
            this.#offscreen_fragment = null;
          }
        }
      }
      /**
       * Update the source that powers `$effect.pending()` inside this boundary,
       * and controls when the current `pending` snippet (if any) is removed.
       * Do not call from inside the class
       * @param {1 | -1} d
       */
      update_pending_count(d) {
        this.#update_pending_count(d);
        this.#local_pending_count += d;
        if (this.#effect_pending) {
          internal_set(this.#effect_pending, this.#local_pending_count);
        }
      }
      get_effect_pending() {
        this.#effect_pending_subscriber();
        return get(
          /** @type {Source<number>} */
          this.#effect_pending
        );
      }
      /** @param {unknown} error */
      error(error) {
        var onerror = this.#props.onerror;
        let failed = this.#props.failed;
        if (this.#is_creating_fallback || !onerror && !failed) {
          throw error;
        }
        if (this.#main_effect) {
          destroy_effect(this.#main_effect);
          this.#main_effect = null;
        }
        if (this.#pending_effect) {
          destroy_effect(this.#pending_effect);
          this.#pending_effect = null;
        }
        if (this.#failed_effect) {
          destroy_effect(this.#failed_effect);
          this.#failed_effect = null;
        }
        if (hydrating) {
          set_hydrate_node(
            /** @type {TemplateNode} */
            this.#hydrate_open
          );
          next();
          set_hydrate_node(skip_nodes());
        }
        var did_reset = false;
        var calling_on_error = false;
        const reset2 = () => {
          if (did_reset) {
            svelte_boundary_reset_noop();
            return;
          }
          did_reset = true;
          if (calling_on_error) {
            svelte_boundary_reset_onerror();
          }
          Batch.ensure();
          this.#local_pending_count = 0;
          if (this.#failed_effect !== null) {
            pause_effect(this.#failed_effect, () => {
              this.#failed_effect = null;
            });
          }
          this.#pending = this.has_pending_snippet();
          this.#main_effect = this.#run(() => {
            this.#is_creating_fallback = false;
            return branch(() => this.#children(this.#anchor));
          });
          if (this.#pending_count > 0) {
            this.#show_pending_snippet();
          } else {
            this.#pending = false;
          }
        };
        var previous_reaction = active_reaction;
        try {
          set_active_reaction(null);
          calling_on_error = true;
          onerror?.(error, reset2);
          calling_on_error = false;
        } catch (error2) {
          invoke_error_boundary(error2, this.#effect && this.#effect.parent);
        } finally {
          set_active_reaction(previous_reaction);
        }
        if (failed) {
          queue_micro_task(() => {
            this.#failed_effect = this.#run(() => {
              Batch.ensure();
              this.#is_creating_fallback = true;
              try {
                return branch(() => {
                  failed(
                    this.#anchor,
                    () => error,
                    () => reset2
                  );
                });
              } catch (error2) {
                invoke_error_boundary(
                  error2,
                  /** @type {Effect} */
                  this.#effect.parent
                );
                return null;
              } finally {
                this.#is_creating_fallback = false;
              }
            });
          });
        }
      }
    };
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/each.js
function set_current_each_item(item) {
  current_each_item = item;
}
function index(_, i) {
  return i;
}
function pause_effects(state2, to_destroy, controlled_anchor) {
  var transitions = [];
  var length = to_destroy.length;
  for (var i = 0; i < length; i++) {
    pause_children(to_destroy[i].e, transitions, true);
  }
  run_out_transitions(transitions, () => {
    var fast_path = transitions.length === 0 && controlled_anchor !== null;
    if (fast_path) {
      var anchor = (
        /** @type {Element} */
        controlled_anchor
      );
      var parent_node = (
        /** @type {Element} */
        anchor.parentNode
      );
      clear_text_content(parent_node);
      parent_node.append(anchor);
      state2.items.clear();
      link(state2, to_destroy[0].prev, to_destroy[length - 1].next);
    }
    for (var i2 = 0; i2 < length; i2++) {
      var item = to_destroy[i2];
      if (!fast_path) {
        state2.items.delete(item.k);
        link(state2, item.prev, item.next);
      }
      destroy_effect(item.e, !fast_path);
    }
    if (state2.first === to_destroy[0]) {
      state2.first = to_destroy[0].prev;
    }
  });
}
function each(node, flags2, get_collection, get_key, render_fn, fallback_fn = null) {
  var anchor = node;
  var items = /* @__PURE__ */ new Map();
  var first = null;
  var is_controlled = (flags2 & EACH_IS_CONTROLLED) !== 0;
  var is_reactive_value = (flags2 & EACH_ITEM_REACTIVE) !== 0;
  var is_reactive_index = (flags2 & EACH_INDEX_REACTIVE) !== 0;
  if (is_controlled) {
    var parent_node = (
      /** @type {Element} */
      node
    );
    anchor = hydrating ? set_hydrate_node(
      /** @type {Comment | Text} */
      get_first_child(parent_node)
    ) : parent_node.appendChild(create_text());
  }
  if (hydrating) {
    hydrate_next();
  }
  var fallback2 = null;
  var each_array = derived_safe_equal(() => {
    var collection = get_collection();
    return is_array(collection) ? collection : collection == null ? [] : array_from(collection);
  });
  var array;
  var first_run = true;
  function commit() {
    reconcile(state2, array, anchor, flags2, get_key);
    if (fallback2 !== null) {
      if (array.length === 0) {
        if (fallback2.fragment) {
          anchor.before(fallback2.fragment);
          fallback2.fragment = null;
        } else {
          resume_effect(fallback2.effect);
        }
        effect2.first = fallback2.effect;
      } else {
        pause_effect(fallback2.effect, () => {
          fallback2 = null;
        });
      }
    }
  }
  var effect2 = block(() => {
    array = /** @type {V[]} */
    get(each_array);
    var length = array.length;
    let mismatch = false;
    if (hydrating) {
      var is_else = read_hydration_instruction(anchor) === HYDRATION_START_ELSE;
      if (is_else !== (length === 0)) {
        anchor = skip_nodes();
        set_hydrate_node(anchor);
        set_hydrating(false);
        mismatch = true;
      }
    }
    var keys = /* @__PURE__ */ new Set();
    var batch = (
      /** @type {Batch} */
      current_batch
    );
    var prev = null;
    var defer = should_defer_append();
    for (var i = 0; i < length; i += 1) {
      if (hydrating && hydrate_node.nodeType === COMMENT_NODE && /** @type {Comment} */
      hydrate_node.data === HYDRATION_END) {
        anchor = /** @type {Comment} */
        hydrate_node;
        mismatch = true;
        set_hydrating(false);
      }
      var value = array[i];
      var key2 = get_key(value, i);
      var item = first_run ? null : items.get(key2);
      if (item) {
        if (is_reactive_value) {
          internal_set(item.v, value);
        }
        if (is_reactive_index) {
          internal_set(
            /** @type {Value<number>} */
            item.i,
            i
          );
        } else {
          item.i = i;
        }
        if (defer) {
          batch.skipped_effects.delete(item.e);
        }
      } else {
        item = create_item(
          first_run ? anchor : null,
          prev,
          value,
          key2,
          i,
          render_fn,
          flags2,
          get_collection
        );
        if (first_run) {
          item.o = true;
          if (prev === null) {
            first = item;
          } else {
            prev.next = item;
          }
          prev = item;
        }
        items.set(key2, item);
      }
      keys.add(key2);
    }
    if (length === 0 && fallback_fn && !fallback2) {
      if (first_run) {
        fallback2 = {
          fragment: null,
          effect: branch(() => fallback_fn(anchor))
        };
      } else {
        var fragment = document.createDocumentFragment();
        var target = create_text();
        fragment.append(target);
        fallback2 = {
          fragment,
          effect: branch(() => fallback_fn(target))
        };
      }
    }
    if (hydrating && length > 0) {
      set_hydrate_node(skip_nodes());
    }
    if (!first_run) {
      if (defer) {
        for (const [key3, item2] of items) {
          if (!keys.has(key3)) {
            batch.skipped_effects.add(item2.e);
          }
        }
        batch.oncommit(commit);
        batch.ondiscard(() => {
        });
      } else {
        commit();
      }
    }
    if (mismatch) {
      set_hydrating(true);
    }
    get(each_array);
  });
  var state2 = { effect: effect2, flags: flags2, items, first };
  first_run = false;
  if (hydrating) {
    anchor = hydrate_node;
  }
}
function reconcile(state2, array, anchor, flags2, get_key) {
  var is_animated = (flags2 & EACH_IS_ANIMATED) !== 0;
  var length = array.length;
  var items = state2.items;
  var current = state2.first;
  var seen2;
  var prev = null;
  var to_animate;
  var matched = [];
  var stashed = [];
  var value;
  var key2;
  var item;
  var i;
  if (is_animated) {
    for (i = 0; i < length; i += 1) {
      value = array[i];
      key2 = get_key(value, i);
      item = /** @type {EachItem} */
      items.get(key2);
      if (item.o) {
        item.a?.measure();
        (to_animate ??= /* @__PURE__ */ new Set()).add(item);
      }
    }
  }
  for (i = 0; i < length; i += 1) {
    value = array[i];
    key2 = get_key(value, i);
    item = /** @type {EachItem} */
    items.get(key2);
    state2.first ??= item;
    if (!item.o) {
      item.o = true;
      var next2 = prev ? prev.next : current;
      link(state2, prev, item);
      link(state2, item, next2);
      move(item, next2, anchor);
      prev = item;
      matched = [];
      stashed = [];
      current = prev.next;
      continue;
    }
    if ((item.e.f & INERT) !== 0) {
      resume_effect(item.e);
      if (is_animated) {
        item.a?.unfix();
        (to_animate ??= /* @__PURE__ */ new Set()).delete(item);
      }
    }
    if (item !== current) {
      if (seen2 !== void 0 && seen2.has(item)) {
        if (matched.length < stashed.length) {
          var start = stashed[0];
          var j;
          prev = start.prev;
          var a = matched[0];
          var b = matched[matched.length - 1];
          for (j = 0; j < matched.length; j += 1) {
            move(matched[j], start, anchor);
          }
          for (j = 0; j < stashed.length; j += 1) {
            seen2.delete(stashed[j]);
          }
          link(state2, a.prev, b.next);
          link(state2, prev, a);
          link(state2, b, start);
          current = start;
          prev = b;
          i -= 1;
          matched = [];
          stashed = [];
        } else {
          seen2.delete(item);
          move(item, current, anchor);
          link(state2, item.prev, item.next);
          link(state2, item, prev === null ? state2.first : prev.next);
          link(state2, prev, item);
          prev = item;
        }
        continue;
      }
      matched = [];
      stashed = [];
      while (current !== null && current.k !== key2) {
        if ((current.e.f & INERT) === 0) {
          (seen2 ??= /* @__PURE__ */ new Set()).add(current);
        }
        stashed.push(current);
        current = current.next;
      }
      if (current === null) {
        continue;
      }
      item = current;
    }
    matched.push(item);
    prev = item;
    current = item.next;
  }
  let has_offscreen_items = items.size > length;
  if (current !== null || seen2 !== void 0) {
    var to_destroy = seen2 === void 0 ? [] : array_from(seen2);
    while (current !== null) {
      if ((current.e.f & INERT) === 0) {
        to_destroy.push(current);
      }
      current = current.next;
    }
    var destroy_length = to_destroy.length;
    has_offscreen_items = items.size - destroy_length > length;
    if (destroy_length > 0) {
      var controlled_anchor = (flags2 & EACH_IS_CONTROLLED) !== 0 && length === 0 ? anchor : null;
      if (is_animated) {
        for (i = 0; i < destroy_length; i += 1) {
          to_destroy[i].a?.measure();
        }
        for (i = 0; i < destroy_length; i += 1) {
          to_destroy[i].a?.fix();
        }
      }
      pause_effects(state2, to_destroy, controlled_anchor);
    }
  }
  if (has_offscreen_items) {
    for (const item2 of items.values()) {
      if (!item2.o) {
        link(state2, prev, item2);
        prev = item2;
      }
    }
  }
  state2.effect.last = prev && prev.e;
  if (is_animated) {
    queue_micro_task(() => {
      if (to_animate === void 0) return;
      for (item of to_animate) {
        item.a?.apply();
      }
    });
  }
}
function create_item(anchor, prev, value, key2, index2, render_fn, flags2, get_collection) {
  var previous_each_item = current_each_item;
  var reactive = (flags2 & EACH_ITEM_REACTIVE) !== 0;
  var mutable = (flags2 & EACH_ITEM_IMMUTABLE) === 0;
  var v = reactive ? mutable ? mutable_source(value, false, false) : source(value) : value;
  var i = (flags2 & EACH_INDEX_REACTIVE) === 0 ? index2 : source(index2);
  if (true_default && reactive) {
    v.trace = () => {
      var collection_index = typeof i === "number" ? index2 : i.v;
      get_collection()[collection_index];
    };
  }
  var item = {
    i,
    v,
    k: key2,
    a: null,
    // @ts-expect-error
    e: null,
    o: false,
    prev,
    next: null
  };
  current_each_item = item;
  try {
    if (anchor === null) {
      var fragment = document.createDocumentFragment();
      fragment.append(anchor = create_text());
    }
    item.e = branch(() => render_fn(
      /** @type {Node} */
      anchor,
      v,
      i,
      get_collection
    ));
    if (prev !== null) {
      prev.next = item;
    }
    return item;
  } finally {
    current_each_item = previous_each_item;
  }
}
function move(item, next2, anchor) {
  var end = item.next ? (
    /** @type {TemplateNode} */
    item.next.e.nodes_start
  ) : anchor;
  var dest = next2 ? (
    /** @type {TemplateNode} */
    next2.e.nodes_start
  ) : anchor;
  var node = (
    /** @type {TemplateNode} */
    item.e.nodes_start
  );
  while (node !== null && node !== end) {
    var next_node = (
      /** @type {TemplateNode} */
      get_next_sibling(node)
    );
    dest.before(node);
    node = next_node;
  }
}
function link(state2, prev, next2) {
  if (prev === null) {
    state2.first = next2;
    state2.effect.first = next2 && next2.e;
  } else {
    if (prev.e.next) {
      prev.e.next.prev = null;
    }
    prev.next = next2;
    prev.e.next = next2 && next2.e;
  }
  if (next2 !== null) {
    if (next2.e.prev) {
      next2.e.prev.next = null;
    }
    next2.prev = prev;
    next2.e.prev = prev && prev.e;
  }
}
var current_each_item;
var init_each = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/each.js"() {
    init_constants();
    init_hydration();
    init_operations();
    init_effects();
    init_sources();
    init_utils();
    init_constants2();
    init_task();
    init_runtime();
    init_esm_env();
    init_deriveds();
    init_batch();
    current_each_item = null;
  }
});

// node_modules/svelte/src/internal/client/reactivity/async.js
function flatten(blockers, sync, async2, fn) {
  const d = is_runes() ? derived : derived_safe_equal;
  if (async2.length === 0 && blockers.length === 0) {
    fn(sync.map(d));
    return;
  }
  var batch = current_batch;
  var parent = (
    /** @type {Effect} */
    active_effect
  );
  var restore = capture();
  function run3() {
    Promise.all(async2.map((expression) => async_derived(expression))).then((result) => {
      restore();
      try {
        fn([...sync.map(d), ...result]);
      } catch (error) {
        if ((parent.f & DESTROYED) === 0) {
          invoke_error_boundary(error, parent);
        }
      }
      batch?.deactivate();
      unset_context();
    }).catch((error) => {
      invoke_error_boundary(error, parent);
    });
  }
  if (blockers.length > 0) {
    Promise.all(blockers).then(() => {
      restore();
      try {
        return run3();
      } finally {
        batch?.deactivate();
        unset_context();
      }
    });
  } else {
    run3();
  }
}
function run_after_blockers(blockers, fn) {
  var each_item = current_each_item;
  flatten(blockers, [], [], (v) => {
    set_current_each_item(each_item);
    fn(v);
  });
}
function capture() {
  var previous_effect = active_effect;
  var previous_reaction = active_reaction;
  var previous_component_context = component_context;
  var previous_batch2 = current_batch;
  if (true_default) {
    var previous_dev_stack = dev_stack;
  }
  return function restore(activate_batch = true) {
    set_active_effect(previous_effect);
    set_active_reaction(previous_reaction);
    set_component_context(previous_component_context);
    if (activate_batch) previous_batch2?.activate();
    if (true_default) {
      set_from_async_derived(null);
      set_dev_stack(previous_dev_stack);
    }
  };
}
async function save(promise) {
  var restore = capture();
  var value = await promise;
  return () => {
    restore();
    return value;
  };
}
async function track_reactivity_loss(promise) {
  var previous_async_effect = current_async_effect;
  var value = await promise;
  return () => {
    set_from_async_derived(previous_async_effect);
    return value;
  };
}
async function* for_await_track_reactivity_loss(iterable) {
  const iterator = iterable[Symbol.asyncIterator]?.() ?? iterable[Symbol.iterator]?.();
  if (iterator === void 0) {
    throw new TypeError("value is not async iterable");
  }
  let normal_completion = false;
  try {
    while (true) {
      const { done, value } = (await track_reactivity_loss(iterator.next()))();
      if (done) {
        normal_completion = true;
        break;
      }
      yield value;
    }
  } finally {
    if (normal_completion && iterator.return !== void 0) {
      return (
        /** @type {TReturn} */
        (await track_reactivity_loss(iterator.return()))().value
      );
    }
  }
}
function unset_context() {
  set_active_effect(null);
  set_active_reaction(null);
  set_component_context(null);
  if (true_default) {
    set_from_async_derived(null);
    set_dev_stack(null);
  }
}
async function async_body(anchor, fn) {
  var boundary2 = get_boundary();
  var batch = (
    /** @type {Batch} */
    current_batch
  );
  var blocking = !boundary2.is_pending();
  boundary2.update_pending_count(1);
  batch.increment(blocking);
  var active = (
    /** @type {Effect} */
    active_effect
  );
  var was_hydrating = hydrating;
  var next_hydrate_node = void 0;
  if (was_hydrating) {
    hydrate_next();
    next_hydrate_node = skip_nodes(false);
  }
  try {
    var promise = fn(anchor);
  } finally {
    if (next_hydrate_node) {
      set_hydrate_node(next_hydrate_node);
      hydrate_next();
    }
  }
  try {
    await promise;
  } catch (error) {
    if (!aborted(active)) {
      invoke_error_boundary(error, active);
    }
  } finally {
    boundary2.update_pending_count(-1);
    batch.decrement(blocking);
    unset_context();
  }
}
function run2(thunks) {
  const restore = capture();
  var boundary2 = get_boundary();
  var batch = (
    /** @type {Batch} */
    current_batch
  );
  var blocking = !boundary2.is_pending();
  boundary2.update_pending_count(1);
  batch.increment(blocking);
  var active = (
    /** @type {Effect} */
    active_effect
  );
  var errored = null;
  const handle_error2 = (error) => {
    errored = { error };
    if (!aborted(active)) {
      invoke_error_boundary(error, active);
    }
  };
  var promise = Promise.resolve(thunks[0]()).catch(handle_error2);
  var promises = [promise];
  for (const fn of thunks.slice(1)) {
    promise = promise.then(() => {
      if (errored) {
        throw errored.error;
      }
      if (aborted(active)) {
        throw STALE_REACTION;
      }
      try {
        restore();
        return fn();
      } finally {
        unset_context();
      }
    }).catch(handle_error2).finally(() => {
      unset_context();
    });
    promises.push(promise);
  }
  promise.then(() => Promise.resolve()).finally(() => {
    boundary2.update_pending_count(-1);
    batch.decrement(blocking);
  });
  return promises;
}
var init_async = __esm({
  "node_modules/svelte/src/internal/client/reactivity/async.js"() {
    init_constants2();
    init_esm_env();
    init_context();
    init_boundary();
    init_error_handling();
    init_runtime();
    init_batch();
    init_deriveds();
    init_effects();
    init_hydration();
    init_each();
  }
});

// node_modules/svelte/src/internal/client/reactivity/deriveds.js
function set_from_async_derived(v) {
  current_async_effect = v;
}
// @__NO_SIDE_EFFECTS__
function derived(fn) {
  var flags2 = DERIVED | DIRTY;
  var parent_derived = active_reaction !== null && (active_reaction.f & DERIVED) !== 0 ? (
    /** @type {Derived} */
    active_reaction
  ) : null;
  if (active_effect !== null) {
    active_effect.f |= EFFECT_PRESERVED;
  }
  const signal = {
    ctx: component_context,
    deps: null,
    effects: null,
    equals,
    f: flags2,
    fn,
    reactions: null,
    rv: 0,
    v: (
      /** @type {V} */
      UNINITIALIZED
    ),
    wv: 0,
    parent: parent_derived ?? active_effect,
    ac: null
  };
  if (true_default && tracing_mode_flag) {
    signal.created = get_error("created at");
  }
  return signal;
}
// @__NO_SIDE_EFFECTS__
function async_derived(fn, location) {
  let parent = (
    /** @type {Effect | null} */
    active_effect
  );
  if (parent === null) {
    async_derived_orphan();
  }
  var boundary2 = (
    /** @type {Boundary} */
    parent.b
  );
  var promise = (
    /** @type {Promise<V>} */
    /** @type {unknown} */
    void 0
  );
  var signal = source(
    /** @type {V} */
    UNINITIALIZED
  );
  var should_suspend = !active_reaction;
  var deferreds = /* @__PURE__ */ new Map();
  async_effect(() => {
    if (true_default) current_async_effect = active_effect;
    var d = deferred();
    promise = d.promise;
    try {
      Promise.resolve(fn()).then(d.resolve, d.reject).then(() => {
        if (batch === current_batch && batch.committed) {
          batch.deactivate();
        }
        unset_context();
      });
    } catch (error) {
      d.reject(error);
      unset_context();
    }
    if (true_default) current_async_effect = null;
    var batch = (
      /** @type {Batch} */
      current_batch
    );
    if (should_suspend) {
      var blocking = !boundary2.is_pending();
      boundary2.update_pending_count(1);
      batch.increment(blocking);
      deferreds.get(batch)?.reject(STALE_REACTION);
      deferreds.delete(batch);
      deferreds.set(batch, d);
    }
    const handler = (value, error = void 0) => {
      current_async_effect = null;
      batch.activate();
      if (error) {
        if (error !== STALE_REACTION) {
          signal.f |= ERROR_VALUE;
          internal_set(signal, error);
        }
      } else {
        if ((signal.f & ERROR_VALUE) !== 0) {
          signal.f ^= ERROR_VALUE;
        }
        internal_set(signal, value);
        for (const [b, d2] of deferreds) {
          deferreds.delete(b);
          if (b === batch) break;
          d2.reject(STALE_REACTION);
        }
        if (true_default && location !== void 0) {
          recent_async_deriveds.add(signal);
          setTimeout(() => {
            if (recent_async_deriveds.has(signal)) {
              await_waterfall(
                /** @type {string} */
                signal.label,
                location
              );
              recent_async_deriveds.delete(signal);
            }
          });
        }
      }
      if (should_suspend) {
        boundary2.update_pending_count(-1);
        batch.decrement(blocking);
      }
    };
    d.promise.then(handler, (e) => handler(null, e || "unknown"));
  });
  teardown(() => {
    for (const d of deferreds.values()) {
      d.reject(STALE_REACTION);
    }
  });
  if (true_default) {
    signal.f |= ASYNC;
  }
  return new Promise((fulfil) => {
    function next2(p) {
      function go() {
        if (p === promise) {
          fulfil(signal);
        } else {
          next2(promise);
        }
      }
      p.then(go, go);
    }
    next2(promise);
  });
}
// @__NO_SIDE_EFFECTS__
function user_derived(fn) {
  const d = /* @__PURE__ */ derived(fn);
  if (!async_mode_flag) push_reaction_value(d);
  return d;
}
// @__NO_SIDE_EFFECTS__
function derived_safe_equal(fn) {
  const signal = /* @__PURE__ */ derived(fn);
  signal.equals = safe_equals;
  return signal;
}
function destroy_derived_effects(derived2) {
  var effects = derived2.effects;
  if (effects !== null) {
    derived2.effects = null;
    for (var i = 0; i < effects.length; i += 1) {
      destroy_effect(
        /** @type {Effect} */
        effects[i]
      );
    }
  }
}
function get_derived_parent_effect(derived2) {
  var parent = derived2.parent;
  while (parent !== null) {
    if ((parent.f & DERIVED) === 0) {
      return (parent.f & DESTROYED) === 0 ? (
        /** @type {Effect} */
        parent
      ) : null;
    }
    parent = parent.parent;
  }
  return null;
}
function execute_derived(derived2) {
  var value;
  var prev_active_effect = active_effect;
  set_active_effect(get_derived_parent_effect(derived2));
  if (true_default) {
    let prev_eager_effects = eager_effects;
    set_eager_effects(/* @__PURE__ */ new Set());
    try {
      if (stack.includes(derived2)) {
        derived_references_self();
      }
      stack.push(derived2);
      derived2.f &= ~WAS_MARKED;
      destroy_derived_effects(derived2);
      value = update_reaction(derived2);
    } finally {
      set_active_effect(prev_active_effect);
      set_eager_effects(prev_eager_effects);
      stack.pop();
    }
  } else {
    try {
      derived2.f &= ~WAS_MARKED;
      destroy_derived_effects(derived2);
      value = update_reaction(derived2);
    } finally {
      set_active_effect(prev_active_effect);
    }
  }
  return value;
}
function update_derived(derived2) {
  var value = execute_derived(derived2);
  if (!derived2.equals(value)) {
    if (!current_batch?.is_fork) {
      derived2.v = value;
    }
    derived2.wv = increment_write_version();
  }
  if (is_destroying_effect) {
    return;
  }
  if (batch_values !== null) {
    if (effect_tracking() || current_batch?.is_fork) {
      batch_values.set(derived2, value);
    }
  } else {
    var status = (derived2.f & CONNECTED) === 0 ? MAYBE_DIRTY : CLEAN;
    set_signal_status(derived2, status);
  }
}
var current_async_effect, recent_async_deriveds, stack;
var init_deriveds = __esm({
  "node_modules/svelte/src/internal/client/reactivity/deriveds.js"() {
    init_esm_env();
    init_constants2();
    init_runtime();
    init_equality();
    init_errors2();
    init_warnings();
    init_effects();
    init_sources();
    init_dev();
    init_flags();
    init_boundary();
    init_context();
    init_constants();
    init_batch();
    init_async();
    init_utils();
    current_async_effect = null;
    recent_async_deriveds = /* @__PURE__ */ new Set();
    stack = [];
  }
});

// node_modules/svelte/src/internal/client/reactivity/sources.js
function set_eager_effects(v) {
  eager_effects = v;
}
function set_eager_effects_deferred() {
  eager_effects_deferred = true;
}
function source(v, stack2) {
  var signal = {
    f: 0,
    // TODO ideally we could skip this altogether, but it causes type errors
    v,
    reactions: null,
    equals,
    rv: 0,
    wv: 0
  };
  if (true_default && tracing_mode_flag) {
    signal.created = stack2 ?? get_error("created at");
    signal.updated = null;
    signal.set_during_effect = false;
    signal.trace = null;
  }
  return signal;
}
// @__NO_SIDE_EFFECTS__
function state(v, stack2) {
  const s = source(v, stack2);
  push_reaction_value(s);
  return s;
}
// @__NO_SIDE_EFFECTS__
function mutable_source(initial_value, immutable = false, trackable = true) {
  const s = source(initial_value);
  if (!immutable) {
    s.equals = safe_equals;
  }
  if (legacy_mode_flag && trackable && component_context !== null && component_context.l !== null) {
    (component_context.l.s ??= []).push(s);
  }
  return s;
}
function mutate(source2, value) {
  set(
    source2,
    untrack(() => get(source2))
  );
  return value;
}
function set(source2, value, should_proxy = false) {
  if (active_reaction !== null && // since we are untracking the function inside `$inspect.with` we need to add this check
  // to ensure we error if state is set inside an inspect effect
  (!untracking || (active_reaction.f & EAGER_EFFECT) !== 0) && is_runes() && (active_reaction.f & (DERIVED | BLOCK_EFFECT | ASYNC | EAGER_EFFECT)) !== 0 && !current_sources?.includes(source2)) {
    state_unsafe_mutation();
  }
  let new_value = should_proxy ? proxy(value) : value;
  if (true_default) {
    tag_proxy(
      new_value,
      /** @type {string} */
      source2.label
    );
  }
  return internal_set(source2, new_value);
}
function internal_set(source2, value) {
  if (!source2.equals(value)) {
    var old_value = source2.v;
    if (is_destroying_effect) {
      old_values.set(source2, value);
    } else {
      old_values.set(source2, old_value);
    }
    source2.v = value;
    var batch = Batch.ensure();
    batch.capture(source2, old_value);
    if (true_default) {
      if (tracing_mode_flag || active_effect !== null) {
        source2.updated ??= /* @__PURE__ */ new Map();
        const count = (source2.updated.get("")?.count ?? 0) + 1;
        source2.updated.set("", { error: (
          /** @type {any} */
          null
        ), count });
        if (tracing_mode_flag || count > 5) {
          const error = get_error("updated at");
          if (error !== null) {
            let entry = source2.updated.get(error.stack);
            if (!entry) {
              entry = { error, count: 0 };
              source2.updated.set(error.stack, entry);
            }
            entry.count++;
          }
        }
      }
      if (active_effect !== null) {
        source2.set_during_effect = true;
      }
    }
    if ((source2.f & DERIVED) !== 0) {
      if ((source2.f & DIRTY) !== 0) {
        execute_derived(
          /** @type {Derived} */
          source2
        );
      }
      set_signal_status(source2, (source2.f & CONNECTED) !== 0 ? CLEAN : MAYBE_DIRTY);
    }
    source2.wv = increment_write_version();
    mark_reactions(source2, DIRTY);
    if (is_runes() && active_effect !== null && (active_effect.f & CLEAN) !== 0 && (active_effect.f & (BRANCH_EFFECT | ROOT_EFFECT)) === 0) {
      if (untracked_writes === null) {
        set_untracked_writes([source2]);
      } else {
        untracked_writes.push(source2);
      }
    }
    if (!batch.is_fork && eager_effects.size > 0 && !eager_effects_deferred) {
      flush_eager_effects();
    }
  }
  return value;
}
function flush_eager_effects() {
  eager_effects_deferred = false;
  var prev_is_updating_effect = is_updating_effect;
  set_is_updating_effect(true);
  const inspects = Array.from(eager_effects);
  try {
    for (const effect2 of inspects) {
      if ((effect2.f & CLEAN) !== 0) {
        set_signal_status(effect2, MAYBE_DIRTY);
      }
      if (is_dirty(effect2)) {
        update_effect(effect2);
      }
    }
  } finally {
    set_is_updating_effect(prev_is_updating_effect);
  }
  eager_effects.clear();
}
function update(source2, d = 1) {
  var value = get(source2);
  var result = d === 1 ? value++ : value--;
  set(source2, value);
  return result;
}
function update_pre(source2, d = 1) {
  var value = get(source2);
  return set(source2, d === 1 ? ++value : --value);
}
function increment(source2) {
  set(source2, source2.v + 1);
}
function mark_reactions(signal, status) {
  var reactions = signal.reactions;
  if (reactions === null) return;
  var runes = is_runes();
  var length = reactions.length;
  for (var i = 0; i < length; i++) {
    var reaction = reactions[i];
    var flags2 = reaction.f;
    if (!runes && reaction === active_effect) continue;
    if (true_default && (flags2 & EAGER_EFFECT) !== 0) {
      eager_effects.add(reaction);
      continue;
    }
    var not_dirty = (flags2 & DIRTY) === 0;
    if (not_dirty) {
      set_signal_status(reaction, status);
    }
    if ((flags2 & DERIVED) !== 0) {
      var derived2 = (
        /** @type {Derived} */
        reaction
      );
      batch_values?.delete(derived2);
      if ((flags2 & WAS_MARKED) === 0) {
        if (flags2 & CONNECTED) {
          reaction.f |= WAS_MARKED;
        }
        mark_reactions(derived2, MAYBE_DIRTY);
      }
    } else if (not_dirty) {
      if ((flags2 & BLOCK_EFFECT) !== 0 && eager_block_effects !== null) {
        eager_block_effects.add(
          /** @type {Effect} */
          reaction
        );
      }
      schedule_effect(
        /** @type {Effect} */
        reaction
      );
    }
  }
}
var eager_effects, old_values, eager_effects_deferred;
var init_sources = __esm({
  "node_modules/svelte/src/internal/client/reactivity/sources.js"() {
    init_esm_env();
    init_runtime();
    init_equality();
    init_constants2();
    init_errors2();
    init_flags();
    init_tracing();
    init_dev();
    init_context();
    init_batch();
    init_proxy();
    init_deriveds();
    eager_effects = /* @__PURE__ */ new Set();
    old_values = /* @__PURE__ */ new Map();
    eager_effects_deferred = false;
  }
});

// node_modules/svelte/src/internal/client/proxy.js
function proxy(value) {
  if (typeof value !== "object" || value === null || STATE_SYMBOL in value) {
    return value;
  }
  const prototype = get_prototype_of(value);
  if (prototype !== object_prototype && prototype !== array_prototype) {
    return value;
  }
  var sources = /* @__PURE__ */ new Map();
  var is_proxied_array = is_array(value);
  var version = state(0);
  var stack2 = true_default && tracing_mode_flag ? get_error("created at") : null;
  var parent_version = update_version;
  var with_parent = (fn) => {
    if (update_version === parent_version) {
      return fn();
    }
    var reaction = active_reaction;
    var version2 = update_version;
    set_active_reaction(null);
    set_update_version(parent_version);
    var result = fn();
    set_active_reaction(reaction);
    set_update_version(version2);
    return result;
  };
  if (is_proxied_array) {
    sources.set("length", state(
      /** @type {any[]} */
      value.length,
      stack2
    ));
    if (true_default) {
      value = /** @type {any} */
      inspectable_array(
        /** @type {any[]} */
        value
      );
    }
  }
  var path = "";
  let updating = false;
  function update_path(new_path) {
    if (updating) return;
    updating = true;
    path = new_path;
    tag(version, `${path} version`);
    for (const [prop2, source2] of sources) {
      tag(source2, get_label(path, prop2));
    }
    updating = false;
  }
  return new Proxy(
    /** @type {any} */
    value,
    {
      defineProperty(_, prop2, descriptor) {
        if (!("value" in descriptor) || descriptor.configurable === false || descriptor.enumerable === false || descriptor.writable === false) {
          state_descriptors_fixed();
        }
        var s = sources.get(prop2);
        if (s === void 0) {
          s = with_parent(() => {
            var s2 = state(descriptor.value, stack2);
            sources.set(prop2, s2);
            if (true_default && typeof prop2 === "string") {
              tag(s2, get_label(path, prop2));
            }
            return s2;
          });
        } else {
          set(s, descriptor.value, true);
        }
        return true;
      },
      deleteProperty(target, prop2) {
        var s = sources.get(prop2);
        if (s === void 0) {
          if (prop2 in target) {
            const s2 = with_parent(() => state(UNINITIALIZED, stack2));
            sources.set(prop2, s2);
            increment(version);
            if (true_default) {
              tag(s2, get_label(path, prop2));
            }
          }
        } else {
          set(s, UNINITIALIZED);
          increment(version);
        }
        return true;
      },
      get(target, prop2, receiver) {
        if (prop2 === STATE_SYMBOL) {
          return value;
        }
        if (true_default && prop2 === PROXY_PATH_SYMBOL) {
          return update_path;
        }
        var s = sources.get(prop2);
        var exists = prop2 in target;
        if (s === void 0 && (!exists || get_descriptor(target, prop2)?.writable)) {
          s = with_parent(() => {
            var p = proxy(exists ? target[prop2] : UNINITIALIZED);
            var s2 = state(p, stack2);
            if (true_default) {
              tag(s2, get_label(path, prop2));
            }
            return s2;
          });
          sources.set(prop2, s);
        }
        if (s !== void 0) {
          var v = get(s);
          return v === UNINITIALIZED ? void 0 : v;
        }
        return Reflect.get(target, prop2, receiver);
      },
      getOwnPropertyDescriptor(target, prop2) {
        var descriptor = Reflect.getOwnPropertyDescriptor(target, prop2);
        if (descriptor && "value" in descriptor) {
          var s = sources.get(prop2);
          if (s) descriptor.value = get(s);
        } else if (descriptor === void 0) {
          var source2 = sources.get(prop2);
          var value2 = source2?.v;
          if (source2 !== void 0 && value2 !== UNINITIALIZED) {
            return {
              enumerable: true,
              configurable: true,
              value: value2,
              writable: true
            };
          }
        }
        return descriptor;
      },
      has(target, prop2) {
        if (prop2 === STATE_SYMBOL) {
          return true;
        }
        var s = sources.get(prop2);
        var has = s !== void 0 && s.v !== UNINITIALIZED || Reflect.has(target, prop2);
        if (s !== void 0 || active_effect !== null && (!has || get_descriptor(target, prop2)?.writable)) {
          if (s === void 0) {
            s = with_parent(() => {
              var p = has ? proxy(target[prop2]) : UNINITIALIZED;
              var s2 = state(p, stack2);
              if (true_default) {
                tag(s2, get_label(path, prop2));
              }
              return s2;
            });
            sources.set(prop2, s);
          }
          var value2 = get(s);
          if (value2 === UNINITIALIZED) {
            return false;
          }
        }
        return has;
      },
      set(target, prop2, value2, receiver) {
        var s = sources.get(prop2);
        var has = prop2 in target;
        if (is_proxied_array && prop2 === "length") {
          for (var i = value2; i < /** @type {Source<number>} */
          s.v; i += 1) {
            var other_s = sources.get(i + "");
            if (other_s !== void 0) {
              set(other_s, UNINITIALIZED);
            } else if (i in target) {
              other_s = with_parent(() => state(UNINITIALIZED, stack2));
              sources.set(i + "", other_s);
              if (true_default) {
                tag(other_s, get_label(path, i));
              }
            }
          }
        }
        if (s === void 0) {
          if (!has || get_descriptor(target, prop2)?.writable) {
            s = with_parent(() => state(void 0, stack2));
            if (true_default) {
              tag(s, get_label(path, prop2));
            }
            set(s, proxy(value2));
            sources.set(prop2, s);
          }
        } else {
          has = s.v !== UNINITIALIZED;
          var p = with_parent(() => proxy(value2));
          set(s, p);
        }
        var descriptor = Reflect.getOwnPropertyDescriptor(target, prop2);
        if (descriptor?.set) {
          descriptor.set.call(receiver, value2);
        }
        if (!has) {
          if (is_proxied_array && typeof prop2 === "string") {
            var ls = (
              /** @type {Source<number>} */
              sources.get("length")
            );
            var n = Number(prop2);
            if (Number.isInteger(n) && n >= ls.v) {
              set(ls, n + 1);
            }
          }
          increment(version);
        }
        return true;
      },
      ownKeys(target) {
        get(version);
        var own_keys = Reflect.ownKeys(target).filter((key3) => {
          var source3 = sources.get(key3);
          return source3 === void 0 || source3.v !== UNINITIALIZED;
        });
        for (var [key2, source2] of sources) {
          if (source2.v !== UNINITIALIZED && !(key2 in target)) {
            own_keys.push(key2);
          }
        }
        return own_keys;
      },
      setPrototypeOf() {
        state_prototype_fixed();
      }
    }
  );
}
function get_label(path, prop2) {
  if (typeof prop2 === "symbol") return `${path}[Symbol(${prop2.description ?? ""})]`;
  if (regex_is_valid_identifier.test(prop2)) return `${path}.${prop2}`;
  return /^\d+$/.test(prop2) ? `${path}[${prop2}]` : `${path}['${prop2}']`;
}
function get_proxied_value(value) {
  try {
    if (value !== null && typeof value === "object" && STATE_SYMBOL in value) {
      return value[STATE_SYMBOL];
    }
  } catch {
  }
  return value;
}
function is(a, b) {
  return Object.is(get_proxied_value(a), get_proxied_value(b));
}
function inspectable_array(array) {
  return new Proxy(array, {
    get(target, prop2, receiver) {
      var value = Reflect.get(target, prop2, receiver);
      if (!ARRAY_MUTATING_METHODS.has(
        /** @type {string} */
        prop2
      )) {
        return value;
      }
      return function(...args) {
        set_eager_effects_deferred();
        var result = value.apply(this, args);
        flush_eager_effects();
        return result;
      };
    }
  });
}
var regex_is_valid_identifier, ARRAY_MUTATING_METHODS;
var init_proxy = __esm({
  "node_modules/svelte/src/internal/client/proxy.js"() {
    init_esm_env();
    init_runtime();
    init_utils();
    init_sources();
    init_constants2();
    init_constants();
    init_errors2();
    init_tracing();
    init_dev();
    init_flags();
    regex_is_valid_identifier = /^[a-zA-Z_$][a-zA-Z_$0-9]*$/;
    ARRAY_MUTATING_METHODS = /* @__PURE__ */ new Set([
      "copyWithin",
      "fill",
      "pop",
      "push",
      "reverse",
      "shift",
      "sort",
      "splice",
      "unshift"
    ]);
  }
});

// node_modules/svelte/src/internal/client/dev/equality.js
function init_array_prototype_warnings() {
  const array_prototype2 = Array.prototype;
  const cleanup = Array.__svelte_cleanup;
  if (cleanup) {
    cleanup();
  }
  const { indexOf, lastIndexOf, includes } = array_prototype2;
  array_prototype2.indexOf = function(item, from_index) {
    const index2 = indexOf.call(this, item, from_index);
    if (index2 === -1) {
      for (let i = from_index ?? 0; i < this.length; i += 1) {
        if (get_proxied_value(this[i]) === item) {
          state_proxy_equality_mismatch("array.indexOf(...)");
          break;
        }
      }
    }
    return index2;
  };
  array_prototype2.lastIndexOf = function(item, from_index) {
    const index2 = lastIndexOf.call(this, item, from_index ?? this.length - 1);
    if (index2 === -1) {
      for (let i = 0; i <= (from_index ?? this.length - 1); i += 1) {
        if (get_proxied_value(this[i]) === item) {
          state_proxy_equality_mismatch("array.lastIndexOf(...)");
          break;
        }
      }
    }
    return index2;
  };
  array_prototype2.includes = function(item, from_index) {
    const has = includes.call(this, item, from_index);
    if (!has) {
      for (let i = 0; i < this.length; i += 1) {
        if (get_proxied_value(this[i]) === item) {
          state_proxy_equality_mismatch("array.includes(...)");
          break;
        }
      }
    }
    return has;
  };
  Array.__svelte_cleanup = () => {
    array_prototype2.indexOf = indexOf;
    array_prototype2.lastIndexOf = lastIndexOf;
    array_prototype2.includes = includes;
  };
}
function strict_equals(a, b, equal = true) {
  try {
    if (a === b !== (get_proxied_value(a) === get_proxied_value(b))) {
      state_proxy_equality_mismatch(equal ? "===" : "!==");
    }
  } catch {
  }
  return a === b === equal;
}
function equals2(a, b, equal = true) {
  if (a == b !== (get_proxied_value(a) == get_proxied_value(b))) {
    state_proxy_equality_mismatch(equal ? "==" : "!=");
  }
  return a == b === equal;
}
var init_equality2 = __esm({
  "node_modules/svelte/src/internal/client/dev/equality.js"() {
    init_warnings();
    init_proxy();
  }
});

// node_modules/svelte/src/internal/client/dom/operations.js
function init_operations2() {
  if ($window !== void 0) {
    return;
  }
  $window = window;
  $document = document;
  is_firefox = /Firefox/.test(navigator.userAgent);
  var element_prototype = Element.prototype;
  var node_prototype = Node.prototype;
  var text_prototype = Text.prototype;
  first_child_getter = get_descriptor(node_prototype, "firstChild").get;
  next_sibling_getter = get_descriptor(node_prototype, "nextSibling").get;
  if (is_extensible(element_prototype)) {
    element_prototype.__click = void 0;
    element_prototype.__className = void 0;
    element_prototype.__attributes = null;
    element_prototype.__style = void 0;
    element_prototype.__e = void 0;
  }
  if (is_extensible(text_prototype)) {
    text_prototype.__t = void 0;
  }
  if (true_default) {
    element_prototype.__svelte_meta = null;
    init_array_prototype_warnings();
  }
}
function create_text(value = "") {
  return document.createTextNode(value);
}
// @__NO_SIDE_EFFECTS__
function get_first_child(node) {
  return first_child_getter.call(node);
}
// @__NO_SIDE_EFFECTS__
function get_next_sibling(node) {
  return next_sibling_getter.call(node);
}
function child(node, is_text) {
  if (!hydrating) {
    return /* @__PURE__ */ get_first_child(node);
  }
  var child2 = (
    /** @type {TemplateNode} */
    /* @__PURE__ */ get_first_child(hydrate_node)
  );
  if (child2 === null) {
    child2 = hydrate_node.appendChild(create_text());
  } else if (is_text && child2.nodeType !== TEXT_NODE) {
    var text2 = create_text();
    child2?.before(text2);
    set_hydrate_node(text2);
    return text2;
  }
  set_hydrate_node(child2);
  return child2;
}
function first_child(fragment, is_text = false) {
  if (!hydrating) {
    var first = (
      /** @type {DocumentFragment} */
      /* @__PURE__ */ get_first_child(
        /** @type {Node} */
        fragment
      )
    );
    if (first instanceof Comment && first.data === "") return /* @__PURE__ */ get_next_sibling(first);
    return first;
  }
  if (is_text && hydrate_node?.nodeType !== TEXT_NODE) {
    var text2 = create_text();
    hydrate_node?.before(text2);
    set_hydrate_node(text2);
    return text2;
  }
  return hydrate_node;
}
function sibling(node, count = 1, is_text = false) {
  let next_sibling = hydrating ? hydrate_node : node;
  var last_sibling;
  while (count--) {
    last_sibling = next_sibling;
    next_sibling = /** @type {TemplateNode} */
    /* @__PURE__ */ get_next_sibling(next_sibling);
  }
  if (!hydrating) {
    return next_sibling;
  }
  if (is_text && next_sibling?.nodeType !== TEXT_NODE) {
    var text2 = create_text();
    if (next_sibling === null) {
      last_sibling?.after(text2);
    } else {
      next_sibling.before(text2);
    }
    set_hydrate_node(text2);
    return text2;
  }
  set_hydrate_node(next_sibling);
  return (
    /** @type {TemplateNode} */
    next_sibling
  );
}
function clear_text_content(node) {
  node.textContent = "";
}
function should_defer_append() {
  if (!async_mode_flag) return false;
  if (eager_block_effects !== null) return false;
  var flags2 = (
    /** @type {Effect} */
    active_effect.f
  );
  return (flags2 & EFFECT_RAN) !== 0;
}
function create_element(tag2, namespace, is2) {
  let options = is2 ? { is: is2 } : void 0;
  if (namespace) {
    return document.createElementNS(namespace, tag2, options);
  }
  return document.createElement(tag2, options);
}
function create_fragment() {
  return document.createDocumentFragment();
}
function create_comment(data = "") {
  return document.createComment(data);
}
function set_attribute(element2, key2, value = "") {
  if (key2.startsWith("xlink:")) {
    element2.setAttributeNS("http://www.w3.org/1999/xlink", key2, value);
    return;
  }
  return element2.setAttribute(key2, value);
}
var $window, $document, is_firefox, first_child_getter, next_sibling_getter;
var init_operations = __esm({
  "node_modules/svelte/src/internal/client/dom/operations.js"() {
    init_hydration();
    init_esm_env();
    init_equality2();
    init_utils();
    init_runtime();
    init_flags();
    init_constants2();
    init_batch();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/misc.js
function autofocus(dom, value) {
  if (value) {
    const body = document.body;
    dom.autofocus = true;
    queue_micro_task(() => {
      if (document.activeElement === body) {
        dom.focus();
      }
    });
  }
}
function remove_textarea_child(dom) {
  if (hydrating && get_first_child(dom) !== null) {
    clear_text_content(dom);
  }
}
function add_form_reset_listener() {
  if (!listening_to_form_reset) {
    listening_to_form_reset = true;
    document.addEventListener(
      "reset",
      (evt) => {
        Promise.resolve().then(() => {
          if (!evt.defaultPrevented) {
            for (
              const e of
              /**@type {HTMLFormElement} */
              evt.target.elements
            ) {
              e.__on_r?.();
            }
          }
        });
      },
      // In the capture phase to guarantee we get noticed of it (no possibility of stopPropagation)
      { capture: true }
    );
  }
}
var listening_to_form_reset;
var init_misc = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/misc.js"() {
    init_hydration();
    init_operations();
    init_task();
    listening_to_form_reset = false;
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/shared.js
function listen(target, events, handler, call_handler_immediately = true) {
  if (call_handler_immediately) {
    handler();
  }
  for (var name of events) {
    target.addEventListener(name, handler);
  }
  teardown(() => {
    for (var name2 of events) {
      target.removeEventListener(name2, handler);
    }
  });
}
function without_reactive_context(fn) {
  var previous_reaction = active_reaction;
  var previous_effect = active_effect;
  set_active_reaction(null);
  set_active_effect(null);
  try {
    return fn();
  } finally {
    set_active_reaction(previous_reaction);
    set_active_effect(previous_effect);
  }
}
function listen_to_event_and_reset_event(element2, event2, handler, on_reset = handler) {
  element2.addEventListener(event2, () => without_reactive_context(handler));
  const prev = element2.__on_r;
  if (prev) {
    element2.__on_r = () => {
      prev();
      on_reset(true);
    };
  } else {
    element2.__on_r = () => on_reset(true);
  }
  add_form_reset_listener();
}
var init_shared = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/shared.js"() {
    init_effects();
    init_runtime();
    init_misc();
  }
});

// node_modules/svelte/src/internal/client/reactivity/effects.js
function validate_effect(rune) {
  if (active_effect === null) {
    if (active_reaction === null) {
      effect_orphan(rune);
    }
    effect_in_unowned_derived();
  }
  if (is_destroying_effect) {
    effect_in_teardown(rune);
  }
}
function push_effect(effect2, parent_effect) {
  var parent_last = parent_effect.last;
  if (parent_last === null) {
    parent_effect.last = parent_effect.first = effect2;
  } else {
    parent_last.next = effect2;
    effect2.prev = parent_last;
    parent_effect.last = effect2;
  }
}
function create_effect(type, fn, sync) {
  var parent = active_effect;
  if (true_default) {
    while (parent !== null && (parent.f & EAGER_EFFECT) !== 0) {
      parent = parent.parent;
    }
  }
  if (parent !== null && (parent.f & INERT) !== 0) {
    type |= INERT;
  }
  var effect2 = {
    ctx: component_context,
    deps: null,
    nodes_start: null,
    nodes_end: null,
    f: type | DIRTY | CONNECTED,
    first: null,
    fn,
    last: null,
    next: null,
    parent,
    b: parent && parent.b,
    prev: null,
    teardown: null,
    transitions: null,
    wv: 0,
    ac: null
  };
  if (true_default) {
    effect2.component_function = dev_current_component_function;
  }
  if (sync) {
    try {
      update_effect(effect2);
      effect2.f |= EFFECT_RAN;
    } catch (e2) {
      destroy_effect(effect2);
      throw e2;
    }
  } else if (fn !== null) {
    schedule_effect(effect2);
  }
  var e = effect2;
  if (sync && e.deps === null && e.teardown === null && e.nodes_start === null && e.first === e.last && // either `null`, or a singular child
  (e.f & EFFECT_PRESERVED) === 0) {
    e = e.first;
    if ((type & BLOCK_EFFECT) !== 0 && (type & EFFECT_TRANSPARENT) !== 0 && e !== null) {
      e.f |= EFFECT_TRANSPARENT;
    }
  }
  if (e !== null) {
    e.parent = parent;
    if (parent !== null) {
      push_effect(e, parent);
    }
    if (active_reaction !== null && (active_reaction.f & DERIVED) !== 0 && (type & ROOT_EFFECT) === 0) {
      var derived2 = (
        /** @type {Derived} */
        active_reaction
      );
      (derived2.effects ??= []).push(e);
    }
  }
  return effect2;
}
function effect_tracking() {
  return active_reaction !== null && !untracking;
}
function teardown(fn) {
  const effect2 = create_effect(RENDER_EFFECT, null, false);
  set_signal_status(effect2, CLEAN);
  effect2.teardown = fn;
  return effect2;
}
function user_effect(fn) {
  validate_effect("$effect");
  if (true_default) {
    define_property(fn, "name", {
      value: "$effect"
    });
  }
  var flags2 = (
    /** @type {Effect} */
    active_effect.f
  );
  var defer = !active_reaction && (flags2 & BRANCH_EFFECT) !== 0 && (flags2 & EFFECT_RAN) === 0;
  if (defer) {
    var context2 = (
      /** @type {ComponentContext} */
      component_context
    );
    (context2.e ??= []).push(fn);
  } else {
    return create_user_effect(fn);
  }
}
function create_user_effect(fn) {
  return create_effect(EFFECT | USER_EFFECT, fn, false);
}
function user_pre_effect(fn) {
  validate_effect("$effect.pre");
  if (true_default) {
    define_property(fn, "name", {
      value: "$effect.pre"
    });
  }
  return create_effect(RENDER_EFFECT | USER_EFFECT, fn, true);
}
function eager_effect(fn) {
  return create_effect(EAGER_EFFECT, fn, true);
}
function effect_root(fn) {
  Batch.ensure();
  const effect2 = create_effect(ROOT_EFFECT | EFFECT_PRESERVED, fn, true);
  return () => {
    destroy_effect(effect2);
  };
}
function component_root(fn) {
  Batch.ensure();
  const effect2 = create_effect(ROOT_EFFECT | EFFECT_PRESERVED, fn, true);
  return (options = {}) => {
    return new Promise((fulfil) => {
      if (options.outro) {
        pause_effect(effect2, () => {
          destroy_effect(effect2);
          fulfil(void 0);
        });
      } else {
        destroy_effect(effect2);
        fulfil(void 0);
      }
    });
  };
}
function effect(fn) {
  return create_effect(EFFECT, fn, false);
}
function legacy_pre_effect(deps, fn) {
  var context2 = (
    /** @type {ComponentContextLegacy} */
    component_context
  );
  var token = { effect: null, ran: false, deps };
  context2.l.$.push(token);
  token.effect = render_effect(() => {
    deps();
    if (token.ran) return;
    token.ran = true;
    untrack(fn);
  });
}
function legacy_pre_effect_reset() {
  var context2 = (
    /** @type {ComponentContextLegacy} */
    component_context
  );
  render_effect(() => {
    for (var token of context2.l.$) {
      token.deps();
      var effect2 = token.effect;
      if ((effect2.f & CLEAN) !== 0) {
        set_signal_status(effect2, MAYBE_DIRTY);
      }
      if (is_dirty(effect2)) {
        update_effect(effect2);
      }
      token.ran = false;
    }
  });
}
function async_effect(fn) {
  return create_effect(ASYNC | EFFECT_PRESERVED, fn, true);
}
function render_effect(fn, flags2 = 0) {
  return create_effect(RENDER_EFFECT | flags2, fn, true);
}
function template_effect(fn, sync = [], async2 = [], blockers = []) {
  flatten(blockers, sync, async2, (values) => {
    create_effect(RENDER_EFFECT, () => fn(...values.map(get)), true);
  });
}
function deferred_template_effect(fn, sync = [], async2 = [], blockers = []) {
  var batch = (
    /** @type {Batch} */
    current_batch
  );
  var is_async = async2.length > 0 || blockers.length > 0;
  if (is_async) batch.increment(true);
  flatten(blockers, sync, async2, (values) => {
    create_effect(EFFECT, () => fn(...values.map(get)), false);
    if (is_async) batch.decrement(true);
  });
}
function block(fn, flags2 = 0) {
  var effect2 = create_effect(BLOCK_EFFECT | flags2, fn, true);
  if (true_default) {
    effect2.dev_stack = dev_stack;
  }
  return effect2;
}
function managed(fn, flags2 = 0) {
  var effect2 = create_effect(MANAGED_EFFECT | flags2, fn, true);
  if (true_default) {
    effect2.dev_stack = dev_stack;
  }
  return effect2;
}
function branch(fn) {
  return create_effect(BRANCH_EFFECT | EFFECT_PRESERVED, fn, true);
}
function execute_effect_teardown(effect2) {
  var teardown2 = effect2.teardown;
  if (teardown2 !== null) {
    const previously_destroying_effect = is_destroying_effect;
    const previous_reaction = active_reaction;
    set_is_destroying_effect(true);
    set_active_reaction(null);
    try {
      teardown2.call(null);
    } finally {
      set_is_destroying_effect(previously_destroying_effect);
      set_active_reaction(previous_reaction);
    }
  }
}
function destroy_effect_children(signal, remove_dom = false) {
  var effect2 = signal.first;
  signal.first = signal.last = null;
  while (effect2 !== null) {
    const controller2 = effect2.ac;
    if (controller2 !== null) {
      without_reactive_context(() => {
        controller2.abort(STALE_REACTION);
      });
    }
    var next2 = effect2.next;
    if ((effect2.f & ROOT_EFFECT) !== 0) {
      effect2.parent = null;
    } else {
      destroy_effect(effect2, remove_dom);
    }
    effect2 = next2;
  }
}
function destroy_block_effect_children(signal) {
  var effect2 = signal.first;
  while (effect2 !== null) {
    var next2 = effect2.next;
    if ((effect2.f & BRANCH_EFFECT) === 0) {
      destroy_effect(effect2);
    }
    effect2 = next2;
  }
}
function destroy_effect(effect2, remove_dom = true) {
  var removed = false;
  if ((remove_dom || (effect2.f & HEAD_EFFECT) !== 0) && effect2.nodes_start !== null && effect2.nodes_end !== null) {
    remove_effect_dom(
      effect2.nodes_start,
      /** @type {TemplateNode} */
      effect2.nodes_end
    );
    removed = true;
  }
  destroy_effect_children(effect2, remove_dom && !removed);
  remove_reactions(effect2, 0);
  set_signal_status(effect2, DESTROYED);
  var transitions = effect2.transitions;
  if (transitions !== null) {
    for (const transition2 of transitions) {
      transition2.stop();
    }
  }
  execute_effect_teardown(effect2);
  var parent = effect2.parent;
  if (parent !== null && parent.first !== null) {
    unlink_effect(effect2);
  }
  if (true_default) {
    effect2.component_function = null;
  }
  effect2.next = effect2.prev = effect2.teardown = effect2.ctx = effect2.deps = effect2.fn = effect2.nodes_start = effect2.nodes_end = effect2.ac = null;
}
function remove_effect_dom(node, end) {
  while (node !== null) {
    var next2 = node === end ? null : (
      /** @type {TemplateNode} */
      get_next_sibling(node)
    );
    node.remove();
    node = next2;
  }
}
function unlink_effect(effect2) {
  var parent = effect2.parent;
  var prev = effect2.prev;
  var next2 = effect2.next;
  if (prev !== null) prev.next = next2;
  if (next2 !== null) next2.prev = prev;
  if (parent !== null) {
    if (parent.first === effect2) parent.first = next2;
    if (parent.last === effect2) parent.last = prev;
  }
}
function pause_effect(effect2, callback, destroy = true) {
  var transitions = [];
  pause_children(effect2, transitions, true);
  run_out_transitions(transitions, () => {
    if (destroy) destroy_effect(effect2);
    if (callback) callback();
  });
}
function run_out_transitions(transitions, fn) {
  var remaining = transitions.length;
  if (remaining > 0) {
    var check = () => --remaining || fn();
    for (var transition2 of transitions) {
      transition2.out(check);
    }
  } else {
    fn();
  }
}
function pause_children(effect2, transitions, local) {
  if ((effect2.f & INERT) !== 0) return;
  effect2.f ^= INERT;
  if (effect2.transitions !== null) {
    for (const transition2 of effect2.transitions) {
      if (transition2.is_global || local) {
        transitions.push(transition2);
      }
    }
  }
  var child2 = effect2.first;
  while (child2 !== null) {
    var sibling2 = child2.next;
    var transparent = (child2.f & EFFECT_TRANSPARENT) !== 0 || // If this is a branch effect without a block effect parent,
    // it means the parent block effect was pruned. In that case,
    // transparency information was transferred to the branch effect.
    (child2.f & BRANCH_EFFECT) !== 0 && (effect2.f & BLOCK_EFFECT) !== 0;
    pause_children(child2, transitions, transparent ? local : false);
    child2 = sibling2;
  }
}
function resume_effect(effect2) {
  resume_children(effect2, true);
}
function resume_children(effect2, local) {
  if ((effect2.f & INERT) === 0) return;
  effect2.f ^= INERT;
  if ((effect2.f & CLEAN) === 0) {
    set_signal_status(effect2, DIRTY);
    schedule_effect(effect2);
  }
  var child2 = effect2.first;
  while (child2 !== null) {
    var sibling2 = child2.next;
    var transparent = (child2.f & EFFECT_TRANSPARENT) !== 0 || (child2.f & BRANCH_EFFECT) !== 0;
    resume_children(child2, transparent ? local : false);
    child2 = sibling2;
  }
  if (effect2.transitions !== null) {
    for (const transition2 of effect2.transitions) {
      if (transition2.is_global || local) {
        transition2.in();
      }
    }
  }
}
function aborted(effect2 = (
  /** @type {Effect} */
  active_effect
)) {
  return (effect2.f & DESTROYED) !== 0;
}
function move_effect(effect2, fragment) {
  var node = effect2.nodes_start;
  var end = effect2.nodes_end;
  while (node !== null) {
    var next2 = node === end ? null : (
      /** @type {TemplateNode} */
      get_next_sibling(node)
    );
    fragment.append(node);
    node = next2;
  }
}
var init_effects = __esm({
  "node_modules/svelte/src/internal/client/reactivity/effects.js"() {
    init_runtime();
    init_constants2();
    init_errors2();
    init_esm_env();
    init_utils();
    init_operations();
    init_context();
    init_batch();
    init_async();
    init_shared();
  }
});

// node_modules/svelte/src/internal/client/legacy.js
function capture_signals(fn) {
  var previous_captured_signals = captured_signals;
  try {
    captured_signals = /* @__PURE__ */ new Set();
    untrack(fn);
    if (previous_captured_signals !== null) {
      for (var signal of captured_signals) {
        previous_captured_signals.add(signal);
      }
    }
    return captured_signals;
  } finally {
    captured_signals = previous_captured_signals;
  }
}
function invalidate_inner_signals(fn) {
  for (var signal of capture_signals(fn)) {
    internal_set(signal, signal.v);
  }
}
var captured_signals;
var init_legacy = __esm({
  "node_modules/svelte/src/internal/client/legacy.js"() {
    init_sources();
    init_runtime();
    captured_signals = null;
  }
});

// node_modules/svelte/src/internal/client/runtime.js
function set_is_updating_effect(value) {
  is_updating_effect = value;
}
function set_is_destroying_effect(value) {
  is_destroying_effect = value;
}
function set_active_reaction(reaction) {
  active_reaction = reaction;
}
function set_active_effect(effect2) {
  active_effect = effect2;
}
function push_reaction_value(value) {
  if (active_reaction !== null && (!async_mode_flag || (active_reaction.f & DERIVED) !== 0)) {
    if (current_sources === null) {
      current_sources = [value];
    } else {
      current_sources.push(value);
    }
  }
}
function set_untracked_writes(value) {
  untracked_writes = value;
}
function set_update_version(value) {
  update_version = value;
}
function increment_write_version() {
  return ++write_version;
}
function is_dirty(reaction) {
  var flags2 = reaction.f;
  if ((flags2 & DIRTY) !== 0) {
    return true;
  }
  if (flags2 & DERIVED) {
    reaction.f &= ~WAS_MARKED;
  }
  if ((flags2 & MAYBE_DIRTY) !== 0) {
    var dependencies = reaction.deps;
    if (dependencies !== null) {
      var length = dependencies.length;
      for (var i = 0; i < length; i++) {
        var dependency = dependencies[i];
        if (is_dirty(
          /** @type {Derived} */
          dependency
        )) {
          update_derived(
            /** @type {Derived} */
            dependency
          );
        }
        if (dependency.wv > reaction.wv) {
          return true;
        }
      }
    }
    if ((flags2 & CONNECTED) !== 0 && // During time traveling we don't want to reset the status so that
    // traversal of the graph in the other batches still happens
    batch_values === null) {
      set_signal_status(reaction, CLEAN);
    }
  }
  return false;
}
function schedule_possible_effect_self_invalidation(signal, effect2, root = true) {
  var reactions = signal.reactions;
  if (reactions === null) return;
  if (!async_mode_flag && current_sources?.includes(signal)) {
    return;
  }
  for (var i = 0; i < reactions.length; i++) {
    var reaction = reactions[i];
    if ((reaction.f & DERIVED) !== 0) {
      schedule_possible_effect_self_invalidation(
        /** @type {Derived} */
        reaction,
        effect2,
        false
      );
    } else if (effect2 === reaction) {
      if (root) {
        set_signal_status(reaction, DIRTY);
      } else if ((reaction.f & CLEAN) !== 0) {
        set_signal_status(reaction, MAYBE_DIRTY);
      }
      schedule_effect(
        /** @type {Effect} */
        reaction
      );
    }
  }
}
function update_reaction(reaction) {
  var previous_deps = new_deps;
  var previous_skipped_deps = skipped_deps;
  var previous_untracked_writes = untracked_writes;
  var previous_reaction = active_reaction;
  var previous_sources = current_sources;
  var previous_component_context = component_context;
  var previous_untracking = untracking;
  var previous_update_version = update_version;
  var flags2 = reaction.f;
  new_deps = /** @type {null | Value[]} */
  null;
  skipped_deps = 0;
  untracked_writes = null;
  active_reaction = (flags2 & (BRANCH_EFFECT | ROOT_EFFECT)) === 0 ? reaction : null;
  current_sources = null;
  set_component_context(reaction.ctx);
  untracking = false;
  update_version = ++read_version;
  if (reaction.ac !== null) {
    without_reactive_context(() => {
      reaction.ac.abort(STALE_REACTION);
    });
    reaction.ac = null;
  }
  try {
    reaction.f |= REACTION_IS_UPDATING;
    var fn = (
      /** @type {Function} */
      reaction.fn
    );
    var result = fn();
    var deps = reaction.deps;
    if (new_deps !== null) {
      var i;
      remove_reactions(reaction, skipped_deps);
      if (deps !== null && skipped_deps > 0) {
        deps.length = skipped_deps + new_deps.length;
        for (i = 0; i < new_deps.length; i++) {
          deps[skipped_deps + i] = new_deps[i];
        }
      } else {
        reaction.deps = deps = new_deps;
      }
      if (is_updating_effect && effect_tracking() && (reaction.f & CONNECTED) !== 0) {
        for (i = skipped_deps; i < deps.length; i++) {
          (deps[i].reactions ??= []).push(reaction);
        }
      }
    } else if (deps !== null && skipped_deps < deps.length) {
      remove_reactions(reaction, skipped_deps);
      deps.length = skipped_deps;
    }
    if (is_runes() && untracked_writes !== null && !untracking && deps !== null && (reaction.f & (DERIVED | MAYBE_DIRTY | DIRTY)) === 0) {
      for (i = 0; i < /** @type {Source[]} */
      untracked_writes.length; i++) {
        schedule_possible_effect_self_invalidation(
          untracked_writes[i],
          /** @type {Effect} */
          reaction
        );
      }
    }
    if (previous_reaction !== null && previous_reaction !== reaction) {
      read_version++;
      if (untracked_writes !== null) {
        if (previous_untracked_writes === null) {
          previous_untracked_writes = untracked_writes;
        } else {
          previous_untracked_writes.push(.../** @type {Source[]} */
          untracked_writes);
        }
      }
    }
    if ((reaction.f & ERROR_VALUE) !== 0) {
      reaction.f ^= ERROR_VALUE;
    }
    return result;
  } catch (error) {
    return handle_error(error);
  } finally {
    reaction.f ^= REACTION_IS_UPDATING;
    new_deps = previous_deps;
    skipped_deps = previous_skipped_deps;
    untracked_writes = previous_untracked_writes;
    active_reaction = previous_reaction;
    current_sources = previous_sources;
    set_component_context(previous_component_context);
    untracking = previous_untracking;
    update_version = previous_update_version;
  }
}
function remove_reaction(signal, dependency) {
  let reactions = dependency.reactions;
  if (reactions !== null) {
    var index2 = index_of.call(reactions, signal);
    if (index2 !== -1) {
      var new_length = reactions.length - 1;
      if (new_length === 0) {
        reactions = dependency.reactions = null;
      } else {
        reactions[index2] = reactions[new_length];
        reactions.pop();
      }
    }
  }
  if (reactions === null && (dependency.f & DERIVED) !== 0 && // Destroying a child effect while updating a parent effect can cause a dependency to appear
  // to be unused, when in fact it is used by the currently-updating parent. Checking `new_deps`
  // allows us to skip the expensive work of disconnecting and immediately reconnecting it
  (new_deps === null || !new_deps.includes(dependency))) {
    set_signal_status(dependency, MAYBE_DIRTY);
    if ((dependency.f & CONNECTED) !== 0) {
      dependency.f ^= CONNECTED;
      dependency.f &= ~WAS_MARKED;
    }
    destroy_derived_effects(
      /** @type {Derived} **/
      dependency
    );
    remove_reactions(
      /** @type {Derived} **/
      dependency,
      0
    );
  }
}
function remove_reactions(signal, start_index) {
  var dependencies = signal.deps;
  if (dependencies === null) return;
  for (var i = start_index; i < dependencies.length; i++) {
    remove_reaction(signal, dependencies[i]);
  }
}
function update_effect(effect2) {
  var flags2 = effect2.f;
  if ((flags2 & DESTROYED) !== 0) {
    return;
  }
  set_signal_status(effect2, CLEAN);
  var previous_effect = active_effect;
  var was_updating_effect = is_updating_effect;
  active_effect = effect2;
  is_updating_effect = true;
  if (true_default) {
    var previous_component_fn = dev_current_component_function;
    set_dev_current_component_function(effect2.component_function);
    var previous_stack = (
      /** @type {any} */
      dev_stack
    );
    set_dev_stack(effect2.dev_stack ?? dev_stack);
  }
  try {
    if ((flags2 & (BLOCK_EFFECT | MANAGED_EFFECT)) !== 0) {
      destroy_block_effect_children(effect2);
    } else {
      destroy_effect_children(effect2);
    }
    execute_effect_teardown(effect2);
    var teardown2 = update_reaction(effect2);
    effect2.teardown = typeof teardown2 === "function" ? teardown2 : null;
    effect2.wv = write_version;
    if (true_default && tracing_mode_flag && (effect2.f & DIRTY) !== 0 && effect2.deps !== null) {
      for (var dep of effect2.deps) {
        if (dep.set_during_effect) {
          dep.wv = increment_write_version();
          dep.set_during_effect = false;
        }
      }
    }
  } finally {
    is_updating_effect = was_updating_effect;
    active_effect = previous_effect;
    if (true_default) {
      set_dev_current_component_function(previous_component_fn);
      set_dev_stack(previous_stack);
    }
  }
}
async function tick() {
  if (async_mode_flag) {
    return new Promise((f) => {
      requestAnimationFrame(() => f());
      setTimeout(() => f());
    });
  }
  await Promise.resolve();
  flushSync();
}
function get(signal) {
  var flags2 = signal.f;
  var is_derived = (flags2 & DERIVED) !== 0;
  captured_signals?.add(signal);
  if (active_reaction !== null && !untracking) {
    var destroyed = active_effect !== null && (active_effect.f & DESTROYED) !== 0;
    if (!destroyed && !current_sources?.includes(signal)) {
      var deps = active_reaction.deps;
      if ((active_reaction.f & REACTION_IS_UPDATING) !== 0) {
        if (signal.rv < read_version) {
          signal.rv = read_version;
          if (new_deps === null && deps !== null && deps[skipped_deps] === signal) {
            skipped_deps++;
          } else if (new_deps === null) {
            new_deps = [signal];
          } else if (!new_deps.includes(signal)) {
            new_deps.push(signal);
          }
        }
      } else {
        (active_reaction.deps ??= []).push(signal);
        var reactions = signal.reactions;
        if (reactions === null) {
          signal.reactions = [active_reaction];
        } else if (!reactions.includes(active_reaction)) {
          reactions.push(active_reaction);
        }
      }
    }
  }
  if (true_default) {
    recent_async_deriveds.delete(signal);
    if (tracing_mode_flag && !untracking && tracing_expressions !== null && active_reaction !== null && tracing_expressions.reaction === active_reaction) {
      if (signal.trace) {
        signal.trace();
      } else {
        var trace2 = get_error("traced at");
        if (trace2) {
          var entry = tracing_expressions.entries.get(signal);
          if (entry === void 0) {
            entry = { traces: [] };
            tracing_expressions.entries.set(signal, entry);
          }
          var last = entry.traces[entry.traces.length - 1];
          if (trace2.stack !== last?.stack) {
            entry.traces.push(trace2);
          }
        }
      }
    }
  }
  if (is_destroying_effect) {
    if (old_values.has(signal)) {
      return old_values.get(signal);
    }
    if (is_derived) {
      var derived2 = (
        /** @type {Derived} */
        signal
      );
      var value = derived2.v;
      if ((derived2.f & CLEAN) === 0 && derived2.reactions !== null || depends_on_old_values(derived2)) {
        value = execute_derived(derived2);
      }
      old_values.set(derived2, value);
      return value;
    }
  } else if (is_derived && (!batch_values?.has(signal) || current_batch?.is_fork && !effect_tracking())) {
    derived2 = /** @type {Derived} */
    signal;
    if (is_dirty(derived2)) {
      update_derived(derived2);
    }
    if (is_updating_effect && effect_tracking() && (derived2.f & CONNECTED) === 0) {
      reconnect(derived2);
    }
  }
  if (batch_values?.has(signal)) {
    return batch_values.get(signal);
  }
  if ((signal.f & ERROR_VALUE) !== 0) {
    throw signal.v;
  }
  return signal.v;
}
function reconnect(derived2) {
  if (derived2.deps === null) return;
  derived2.f ^= CONNECTED;
  for (const dep of derived2.deps) {
    (dep.reactions ??= []).push(derived2);
    if ((dep.f & DERIVED) !== 0 && (dep.f & CONNECTED) === 0) {
      reconnect(
        /** @type {Derived} */
        dep
      );
    }
  }
}
function depends_on_old_values(derived2) {
  if (derived2.v === UNINITIALIZED) return true;
  if (derived2.deps === null) return false;
  for (const dep of derived2.deps) {
    if (old_values.has(dep)) {
      return true;
    }
    if ((dep.f & DERIVED) !== 0 && depends_on_old_values(
      /** @type {Derived} */
      dep
    )) {
      return true;
    }
  }
  return false;
}
function safe_get(signal) {
  return signal && get(signal);
}
function untrack(fn) {
  var previous_untracking = untracking;
  try {
    untracking = true;
    return fn();
  } finally {
    untracking = previous_untracking;
  }
}
function set_signal_status(signal, status) {
  signal.f = signal.f & STATUS_MASK | status;
}
function exclude_from_object(obj, keys) {
  var result = {};
  for (var key2 in obj) {
    if (!keys.includes(key2)) {
      result[key2] = obj[key2];
    }
  }
  for (var symbol of Object.getOwnPropertySymbols(obj)) {
    if (Object.propertyIsEnumerable.call(obj, symbol) && !keys.includes(symbol)) {
      result[symbol] = obj[symbol];
    }
  }
  return result;
}
function deep_read_state(value) {
  if (typeof value !== "object" || !value || value instanceof EventTarget) {
    return;
  }
  if (STATE_SYMBOL in value) {
    deep_read(value);
  } else if (!Array.isArray(value)) {
    for (let key2 in value) {
      const prop2 = value[key2];
      if (typeof prop2 === "object" && prop2 && STATE_SYMBOL in prop2) {
        deep_read(prop2);
      }
    }
  }
}
function deep_read(value, visited = /* @__PURE__ */ new Set()) {
  if (typeof value === "object" && value !== null && // We don't want to traverse DOM elements
  !(value instanceof EventTarget) && !visited.has(value)) {
    visited.add(value);
    if (value instanceof Date) {
      value.getTime();
    }
    for (let key2 in value) {
      try {
        deep_read(value[key2], visited);
      } catch (e) {
      }
    }
    const proto = get_prototype_of(value);
    if (proto !== Object.prototype && proto !== Array.prototype && proto !== Map.prototype && proto !== Set.prototype && proto !== Date.prototype) {
      const descriptors = get_descriptors(proto);
      for (let key2 in descriptors) {
        const get3 = descriptors[key2].get;
        if (get3) {
          try {
            get3.call(value);
          } catch (e) {
          }
        }
      }
    }
  }
}
var is_updating_effect, is_destroying_effect, active_reaction, untracking, active_effect, current_sources, new_deps, skipped_deps, untracked_writes, write_version, read_version, update_version, STATUS_MASK;
var init_runtime = __esm({
  "node_modules/svelte/src/internal/client/runtime.js"() {
    init_esm_env();
    init_utils();
    init_effects();
    init_constants2();
    init_sources();
    init_deriveds();
    init_flags();
    init_tracing();
    init_dev();
    init_context();
    init_warnings();
    init_batch();
    init_error_handling();
    init_constants();
    init_legacy();
    init_shared();
    is_updating_effect = false;
    is_destroying_effect = false;
    active_reaction = null;
    untracking = false;
    active_effect = null;
    current_sources = null;
    new_deps = null;
    skipped_deps = 0;
    untracked_writes = null;
    write_version = 1;
    read_version = 0;
    update_version = read_version;
    STATUS_MASK = ~(DIRTY | MAYBE_DIRTY | CLEAN);
  }
});

// node_modules/svelte/src/attachments/index.js
function createAttachmentKey() {
  return Symbol(ATTACHMENT_KEY);
}
var init_attachments = __esm({
  "node_modules/svelte/src/attachments/index.js"() {
    init_client();
    init_constants();
    init_index_client();
    init_effects();
  }
});

// node_modules/svelte/src/utils.js
function hash(str) {
  str = str.replace(regex_return_characters, "");
  let hash2 = 5381;
  let i = str.length;
  while (i--) hash2 = (hash2 << 5) - hash2 ^ str.charCodeAt(i);
  return (hash2 >>> 0).toString(36);
}
function is_void(name) {
  return VOID_ELEMENT_NAMES.includes(name) || name.toLowerCase() === "!doctype";
}
function is_capture_event(name) {
  return name.endsWith("capture") && name !== "gotpointercapture" && name !== "lostpointercapture";
}
function can_delegate_event(event_name) {
  return DELEGATED_EVENTS.includes(event_name);
}
function is_boolean_attribute(name) {
  return DOM_BOOLEAN_ATTRIBUTES.includes(name);
}
function normalize_attribute(name) {
  name = name.toLowerCase();
  return ATTRIBUTE_ALIASES[name] ?? name;
}
function is_passive_event(name) {
  return PASSIVE_EVENTS.includes(name);
}
function is_raw_text_element(name) {
  return RAW_TEXT_ELEMENTS.includes(
    /** @type {typeof RAW_TEXT_ELEMENTS[number]} */
    name
  );
}
function sanitize_location(location) {
  return (
    /** @type {T} */
    location?.replace(/\//g, "/\u200B")
  );
}
var regex_return_characters, VOID_ELEMENT_NAMES, DELEGATED_EVENTS, DOM_BOOLEAN_ATTRIBUTES, ATTRIBUTE_ALIASES, DOM_PROPERTIES, PASSIVE_EVENTS, STATE_CREATION_RUNES, RUNES, RAW_TEXT_ELEMENTS;
var init_utils2 = __esm({
  "node_modules/svelte/src/utils.js"() {
    regex_return_characters = /\r/g;
    VOID_ELEMENT_NAMES = [
      "area",
      "base",
      "br",
      "col",
      "command",
      "embed",
      "hr",
      "img",
      "input",
      "keygen",
      "link",
      "meta",
      "param",
      "source",
      "track",
      "wbr"
    ];
    DELEGATED_EVENTS = [
      "beforeinput",
      "click",
      "change",
      "dblclick",
      "contextmenu",
      "focusin",
      "focusout",
      "input",
      "keydown",
      "keyup",
      "mousedown",
      "mousemove",
      "mouseout",
      "mouseover",
      "mouseup",
      "pointerdown",
      "pointermove",
      "pointerout",
      "pointerover",
      "pointerup",
      "touchend",
      "touchmove",
      "touchstart"
    ];
    DOM_BOOLEAN_ATTRIBUTES = [
      "allowfullscreen",
      "async",
      "autofocus",
      "autoplay",
      "checked",
      "controls",
      "default",
      "disabled",
      "formnovalidate",
      "indeterminate",
      "inert",
      "ismap",
      "loop",
      "multiple",
      "muted",
      "nomodule",
      "novalidate",
      "open",
      "playsinline",
      "readonly",
      "required",
      "reversed",
      "seamless",
      "selected",
      "webkitdirectory",
      "defer",
      "disablepictureinpicture",
      "disableremoteplayback"
    ];
    ATTRIBUTE_ALIASES = {
      // no `class: 'className'` because we handle that separately
      formnovalidate: "formNoValidate",
      ismap: "isMap",
      nomodule: "noModule",
      playsinline: "playsInline",
      readonly: "readOnly",
      defaultvalue: "defaultValue",
      defaultchecked: "defaultChecked",
      srcobject: "srcObject",
      novalidate: "noValidate",
      allowfullscreen: "allowFullscreen",
      disablepictureinpicture: "disablePictureInPicture",
      disableremoteplayback: "disableRemotePlayback"
    };
    DOM_PROPERTIES = [
      ...DOM_BOOLEAN_ATTRIBUTES,
      "formNoValidate",
      "isMap",
      "noModule",
      "playsInline",
      "readOnly",
      "value",
      "volume",
      "defaultValue",
      "defaultChecked",
      "srcObject",
      "noValidate",
      "allowFullscreen",
      "disablePictureInPicture",
      "disableRemotePlayback"
    ];
    PASSIVE_EVENTS = ["touchstart", "touchmove"];
    STATE_CREATION_RUNES = /** @type {const} */
    [
      "$state",
      "$state.raw",
      "$derived",
      "$derived.by"
    ];
    RUNES = /** @type {const} */
    [
      ...STATE_CREATION_RUNES,
      "$state.eager",
      "$state.snapshot",
      "$props",
      "$props.id",
      "$bindable",
      "$effect",
      "$effect.pre",
      "$effect.tracking",
      "$effect.root",
      "$effect.pending",
      "$inspect",
      "$inspect().with",
      "$inspect.trace",
      "$host"
    ];
    RAW_TEXT_ELEMENTS = /** @type {const} */
    ["textarea", "script", "style", "title"];
  }
});

// node_modules/svelte/src/internal/client/dev/assign.js
function compare(a, b, property, location) {
  if (a !== b) {
    assignment_value_stale(
      property,
      /** @type {string} */
      sanitize_location(location)
    );
  }
  return a;
}
function assign(object, property, value, location) {
  return compare(
    object[property] = value,
    untrack(() => object[property]),
    property,
    location
  );
}
function assign_and(object, property, value, location) {
  return compare(
    object[property] &&= value,
    untrack(() => object[property]),
    property,
    location
  );
}
function assign_or(object, property, value, location) {
  return compare(
    object[property] ||= value,
    untrack(() => object[property]),
    property,
    location
  );
}
function assign_nullish(object, property, value, location) {
  return compare(
    object[property] ??= value,
    untrack(() => object[property]),
    property,
    location
  );
}
var init_assign = __esm({
  "node_modules/svelte/src/internal/client/dev/assign.js"() {
    init_utils2();
    init_runtime();
    init_warnings();
  }
});

// node_modules/svelte/src/internal/client/dev/css.js
function register_style(hash2, style) {
  var styles = all_styles.get(hash2);
  if (!styles) {
    styles = /* @__PURE__ */ new Set();
    all_styles.set(hash2, styles);
  }
  styles.add(style);
}
function cleanup_styles(hash2) {
  var styles = all_styles.get(hash2);
  if (!styles) return;
  for (const style of styles) {
    style.remove();
  }
  all_styles.delete(hash2);
}
var all_styles;
var init_css = __esm({
  "node_modules/svelte/src/internal/client/dev/css.js"() {
    all_styles = /* @__PURE__ */ new Map();
  }
});

// node_modules/svelte/src/internal/client/dev/elements.js
function add_locations(fn, filename, locations) {
  return (...args) => {
    const dom = fn(...args);
    var node = hydrating ? dom : dom.nodeType === DOCUMENT_FRAGMENT_NODE ? dom.firstChild : dom;
    assign_locations(node, filename, locations);
    return dom;
  };
}
function assign_location(element2, filename, location) {
  element2.__svelte_meta = {
    parent: dev_stack,
    loc: { file: filename, line: location[0], column: location[1] }
  };
  if (location[2]) {
    assign_locations(element2.firstChild, filename, location[2]);
  }
}
function assign_locations(node, filename, locations) {
  var i = 0;
  var depth = 0;
  while (node && i < locations.length) {
    if (hydrating && node.nodeType === COMMENT_NODE) {
      var comment2 = (
        /** @type {Comment} */
        node
      );
      if (comment2.data === HYDRATION_START || comment2.data === HYDRATION_START_ELSE) depth += 1;
      else if (comment2.data[0] === HYDRATION_END) depth -= 1;
    }
    if (depth === 0 && node.nodeType === ELEMENT_NODE) {
      assign_location(
        /** @type {Element} */
        node,
        filename,
        locations[i++]
      );
    }
    node = node.nextSibling;
  }
}
var init_elements = __esm({
  "node_modules/svelte/src/internal/client/dev/elements.js"() {
    init_constants2();
    init_constants();
    init_hydration();
    init_context();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/events.js
function replay_events(dom) {
  if (!hydrating) return;
  dom.removeAttribute("onload");
  dom.removeAttribute("onerror");
  const event2 = dom.__e;
  if (event2 !== void 0) {
    dom.__e = void 0;
    queueMicrotask(() => {
      if (dom.isConnected) {
        dom.dispatchEvent(event2);
      }
    });
  }
}
function create_event(event_name, dom, handler, options = {}) {
  function target_handler(event2) {
    if (!options.capture) {
      handle_event_propagation.call(dom, event2);
    }
    if (!event2.cancelBubble) {
      return without_reactive_context(() => {
        return handler?.call(this, event2);
      });
    }
  }
  if (event_name.startsWith("pointer") || event_name.startsWith("touch") || event_name === "wheel") {
    queue_micro_task(() => {
      dom.addEventListener(event_name, target_handler, options);
    });
  } else {
    dom.addEventListener(event_name, target_handler, options);
  }
  return target_handler;
}
function event(event_name, dom, handler, capture2, passive2) {
  var options = { capture: capture2, passive: passive2 };
  var target_handler = create_event(event_name, dom, handler, options);
  if (dom === document.body || // @ts-ignore
  dom === window || // @ts-ignore
  dom === document || // Firefox has quirky behavior, it can happen that we still get "canplay" events when the element is already removed
  dom instanceof HTMLMediaElement) {
    teardown(() => {
      dom.removeEventListener(event_name, target_handler, options);
    });
  }
}
function delegate(events) {
  for (var i = 0; i < events.length; i++) {
    all_registered_events.add(events[i]);
  }
  for (var fn of root_event_handles) {
    fn(events);
  }
}
function handle_event_propagation(event2) {
  var handler_element = this;
  var owner_document = (
    /** @type {Node} */
    handler_element.ownerDocument
  );
  var event_name = event2.type;
  var path = event2.composedPath?.() || [];
  var current_target = (
    /** @type {null | Element} */
    path[0] || event2.target
  );
  last_propagated_event = event2;
  var path_idx = 0;
  var handled_at = last_propagated_event === event2 && event2.__root;
  if (handled_at) {
    var at_idx = path.indexOf(handled_at);
    if (at_idx !== -1 && (handler_element === document || handler_element === /** @type {any} */
    window)) {
      event2.__root = handler_element;
      return;
    }
    var handler_idx = path.indexOf(handler_element);
    if (handler_idx === -1) {
      return;
    }
    if (at_idx <= handler_idx) {
      path_idx = at_idx;
    }
  }
  current_target = /** @type {Element} */
  path[path_idx] || event2.target;
  if (current_target === handler_element) return;
  define_property(event2, "currentTarget", {
    configurable: true,
    get() {
      return current_target || owner_document;
    }
  });
  var previous_reaction = active_reaction;
  var previous_effect = active_effect;
  set_active_reaction(null);
  set_active_effect(null);
  try {
    var throw_error;
    var other_errors = [];
    while (current_target !== null) {
      var parent_element = current_target.assignedSlot || current_target.parentNode || /** @type {any} */
      current_target.host || null;
      try {
        var delegated = current_target["__" + event_name];
        if (delegated != null && (!/** @type {any} */
        current_target.disabled || // DOM could've been updated already by the time this is reached, so we check this as well
        // -> the target could not have been disabled because it emits the event in the first place
        event2.target === current_target)) {
          delegated.call(current_target, event2);
        }
      } catch (error) {
        if (throw_error) {
          other_errors.push(error);
        } else {
          throw_error = error;
        }
      }
      if (event2.cancelBubble || parent_element === handler_element || parent_element === null) {
        break;
      }
      current_target = parent_element;
    }
    if (throw_error) {
      for (let error of other_errors) {
        queueMicrotask(() => {
          throw error;
        });
      }
      throw throw_error;
    }
  } finally {
    event2.__root = handler_element;
    delete event2.currentTarget;
    set_active_reaction(previous_reaction);
    set_active_effect(previous_effect);
  }
}
function apply(thunk, element2, args, component2, loc, has_side_effects = false, remove_parens = false) {
  let handler;
  let error;
  try {
    handler = thunk();
  } catch (e) {
    error = e;
  }
  if (typeof handler !== "function" && (has_side_effects || handler != null || error)) {
    const filename = component2?.[FILENAME];
    const location = loc ? ` at ${filename}:${loc[0]}:${loc[1]}` : ` in ${filename}`;
    const phase = args[0]?.eventPhase < Event.BUBBLING_PHASE ? "capture" : "";
    const event_name = args[0]?.type + phase;
    const description = `\`${event_name}\` handler${location}`;
    const suggestion = remove_parens ? "remove the trailing `()`" : "add a leading `() =>`";
    event_handler_invalid(description, suggestion);
    if (error) {
      throw error;
    }
  }
  handler?.apply(element2, args);
}
var all_registered_events, root_event_handles, last_propagated_event;
var init_events = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/events.js"() {
    init_effects();
    init_utils();
    init_hydration();
    init_task();
    init_constants();
    init_warnings();
    init_runtime();
    init_shared();
    all_registered_events = /* @__PURE__ */ new Set();
    root_event_handles = /* @__PURE__ */ new Set();
    last_propagated_event = null;
  }
});

// node_modules/svelte/src/internal/client/dom/reconciler.js
function create_fragment_from_html(html3) {
  var elem = document.createElement("template");
  elem.innerHTML = html3.replaceAll("<!>", "<!---->");
  return elem.content;
}
var init_reconciler = __esm({
  "node_modules/svelte/src/internal/client/dom/reconciler.js"() {
  }
});

// node_modules/svelte/src/internal/client/dom/template.js
function assign_nodes(start, end) {
  var effect2 = (
    /** @type {Effect} */
    active_effect
  );
  if (effect2.nodes_start === null) {
    effect2.nodes_start = start;
    effect2.nodes_end = end;
  }
}
// @__NO_SIDE_EFFECTS__
function from_html(content, flags2) {
  var is_fragment = (flags2 & TEMPLATE_FRAGMENT) !== 0;
  var use_import_node = (flags2 & TEMPLATE_USE_IMPORT_NODE) !== 0;
  var node;
  var has_start = !content.startsWith("<!>");
  return () => {
    if (hydrating) {
      assign_nodes(hydrate_node, null);
      return hydrate_node;
    }
    if (node === void 0) {
      node = create_fragment_from_html(has_start ? content : "<!>" + content);
      if (!is_fragment) node = /** @type {Node} */
      get_first_child(node);
    }
    var clone2 = (
      /** @type {TemplateNode} */
      use_import_node || is_firefox ? document.importNode(node, true) : node.cloneNode(true)
    );
    if (is_fragment) {
      var start = (
        /** @type {TemplateNode} */
        get_first_child(clone2)
      );
      var end = (
        /** @type {TemplateNode} */
        clone2.lastChild
      );
      assign_nodes(start, end);
    } else {
      assign_nodes(clone2, clone2);
    }
    return clone2;
  };
}
// @__NO_SIDE_EFFECTS__
function from_namespace(content, flags2, ns = "svg") {
  var has_start = !content.startsWith("<!>");
  var is_fragment = (flags2 & TEMPLATE_FRAGMENT) !== 0;
  var wrapped = `<${ns}>${has_start ? content : "<!>" + content}</${ns}>`;
  var node;
  return () => {
    if (hydrating) {
      assign_nodes(hydrate_node, null);
      return hydrate_node;
    }
    if (!node) {
      var fragment = (
        /** @type {DocumentFragment} */
        create_fragment_from_html(wrapped)
      );
      var root = (
        /** @type {Element} */
        get_first_child(fragment)
      );
      if (is_fragment) {
        node = document.createDocumentFragment();
        while (get_first_child(root)) {
          node.appendChild(
            /** @type {Node} */
            get_first_child(root)
          );
        }
      } else {
        node = /** @type {Element} */
        get_first_child(root);
      }
    }
    var clone2 = (
      /** @type {TemplateNode} */
      node.cloneNode(true)
    );
    if (is_fragment) {
      var start = (
        /** @type {TemplateNode} */
        get_first_child(clone2)
      );
      var end = (
        /** @type {TemplateNode} */
        clone2.lastChild
      );
      assign_nodes(start, end);
    } else {
      assign_nodes(clone2, clone2);
    }
    return clone2;
  };
}
// @__NO_SIDE_EFFECTS__
function from_svg(content, flags2) {
  return /* @__PURE__ */ from_namespace(content, flags2, "svg");
}
// @__NO_SIDE_EFFECTS__
function from_mathml(content, flags2) {
  return /* @__PURE__ */ from_namespace(content, flags2, "math");
}
function fragment_from_tree(structure, ns) {
  var fragment = create_fragment();
  for (var item of structure) {
    if (typeof item === "string") {
      fragment.append(create_text(item));
      continue;
    }
    if (item === void 0 || item[0][0] === "/") {
      fragment.append(create_comment(item ? item[0].slice(3) : ""));
      continue;
    }
    const [name, attributes2, ...children] = item;
    const namespace = name === "svg" ? NAMESPACE_SVG : name === "math" ? NAMESPACE_MATHML : ns;
    var element2 = create_element(name, namespace, attributes2?.is);
    for (var key2 in attributes2) {
      set_attribute(element2, key2, attributes2[key2]);
    }
    if (children.length > 0) {
      var target = element2.tagName === "TEMPLATE" ? (
        /** @type {HTMLTemplateElement} */
        element2.content
      ) : element2;
      target.append(
        fragment_from_tree(children, element2.tagName === "foreignObject" ? void 0 : namespace)
      );
    }
    fragment.append(element2);
  }
  return fragment;
}
// @__NO_SIDE_EFFECTS__
function from_tree(structure, flags2) {
  var is_fragment = (flags2 & TEMPLATE_FRAGMENT) !== 0;
  var use_import_node = (flags2 & TEMPLATE_USE_IMPORT_NODE) !== 0;
  var node;
  return () => {
    if (hydrating) {
      assign_nodes(hydrate_node, null);
      return hydrate_node;
    }
    if (node === void 0) {
      const ns = (flags2 & TEMPLATE_USE_SVG) !== 0 ? NAMESPACE_SVG : (flags2 & TEMPLATE_USE_MATHML) !== 0 ? NAMESPACE_MATHML : void 0;
      node = fragment_from_tree(structure, ns);
      if (!is_fragment) node = /** @type {Node} */
      get_first_child(node);
    }
    var clone2 = (
      /** @type {TemplateNode} */
      use_import_node || is_firefox ? document.importNode(node, true) : node.cloneNode(true)
    );
    if (is_fragment) {
      var start = (
        /** @type {TemplateNode} */
        get_first_child(clone2)
      );
      var end = (
        /** @type {TemplateNode} */
        clone2.lastChild
      );
      assign_nodes(start, end);
    } else {
      assign_nodes(clone2, clone2);
    }
    return clone2;
  };
}
function with_script(fn) {
  return () => run_scripts(fn());
}
function run_scripts(node) {
  if (hydrating) return node;
  const is_fragment = node.nodeType === DOCUMENT_FRAGMENT_NODE;
  const scripts = (
    /** @type {HTMLElement} */
    node.tagName === "SCRIPT" ? [
      /** @type {HTMLScriptElement} */
      node
    ] : node.querySelectorAll("script")
  );
  const effect2 = (
    /** @type {Effect} */
    active_effect
  );
  for (const script of scripts) {
    const clone2 = document.createElement("script");
    for (var attribute of script.attributes) {
      clone2.setAttribute(attribute.name, attribute.value);
    }
    clone2.textContent = script.textContent;
    if (is_fragment ? node.firstChild === script : node === script) {
      effect2.nodes_start = clone2;
    }
    if (is_fragment ? node.lastChild === script : node === script) {
      effect2.nodes_end = clone2;
    }
    script.replaceWith(clone2);
  }
  return node;
}
function text(value = "") {
  if (!hydrating) {
    var t = create_text(value + "");
    assign_nodes(t, t);
    return t;
  }
  var node = hydrate_node;
  if (node.nodeType !== TEXT_NODE) {
    node.before(node = create_text());
    set_hydrate_node(node);
  }
  assign_nodes(node, node);
  return node;
}
function comment() {
  if (hydrating) {
    assign_nodes(hydrate_node, null);
    return hydrate_node;
  }
  var frag = document.createDocumentFragment();
  var start = document.createComment("");
  var anchor = create_text();
  frag.append(start, anchor);
  assign_nodes(start, anchor);
  return frag;
}
function append(anchor, dom) {
  if (hydrating) {
    var effect2 = (
      /** @type {Effect} */
      active_effect
    );
    if ((effect2.f & EFFECT_RAN) === 0 || effect2.nodes_end === null) {
      effect2.nodes_end = hydrate_node;
    }
    hydrate_next();
    return;
  }
  if (anchor === null) {
    return;
  }
  anchor.before(
    /** @type {Node} */
    dom
  );
}
function props_id() {
  if (hydrating && hydrate_node && hydrate_node.nodeType === COMMENT_NODE && hydrate_node.textContent?.startsWith(`$`)) {
    const id = hydrate_node.textContent.substring(1);
    hydrate_next();
    return id;
  }
  (window.__svelte ??= {}).uid ??= 1;
  return `c${window.__svelte.uid++}`;
}
var init_template = __esm({
  "node_modules/svelte/src/internal/client/dom/template.js"() {
    init_hydration();
    init_operations();
    init_reconciler();
    init_runtime();
    init_constants();
    init_constants2();
  }
});

// node_modules/svelte/src/internal/client/render.js
function set_should_intro(value) {
  should_intro = value;
}
function set_text(text2, value) {
  var str = value == null ? "" : typeof value === "object" ? value + "" : value;
  if (str !== (text2.__t ??= text2.nodeValue)) {
    text2.__t = str;
    text2.nodeValue = str + "";
  }
}
function mount(component2, options) {
  return _mount(component2, options);
}
function hydrate(component2, options) {
  init_operations2();
  options.intro = options.intro ?? false;
  const target = options.target;
  const was_hydrating = hydrating;
  const previous_hydrate_node = hydrate_node;
  try {
    var anchor = (
      /** @type {TemplateNode} */
      get_first_child(target)
    );
    while (anchor && (anchor.nodeType !== COMMENT_NODE || /** @type {Comment} */
    anchor.data !== HYDRATION_START)) {
      anchor = /** @type {TemplateNode} */
      get_next_sibling(anchor);
    }
    if (!anchor) {
      throw HYDRATION_ERROR;
    }
    set_hydrating(true);
    set_hydrate_node(
      /** @type {Comment} */
      anchor
    );
    const instance = _mount(component2, { ...options, anchor });
    set_hydrating(false);
    return (
      /**  @type {Exports} */
      instance
    );
  } catch (error) {
    if (error instanceof Error && error.message.split("\n").some((line) => line.startsWith("https://svelte.dev/e/"))) {
      throw error;
    }
    if (error !== HYDRATION_ERROR) {
      console.warn("Failed to hydrate: ", error);
    }
    if (options.recover === false) {
      hydration_failed();
    }
    init_operations2();
    clear_text_content(target);
    set_hydrating(false);
    return mount(component2, options);
  } finally {
    set_hydrating(was_hydrating);
    set_hydrate_node(previous_hydrate_node);
  }
}
function _mount(Component, { target, anchor, props = {}, events, context: context2, intro = true }) {
  init_operations2();
  var registered_events = /* @__PURE__ */ new Set();
  var event_handle = (events2) => {
    for (var i = 0; i < events2.length; i++) {
      var event_name = events2[i];
      if (registered_events.has(event_name)) continue;
      registered_events.add(event_name);
      var passive2 = is_passive_event(event_name);
      target.addEventListener(event_name, handle_event_propagation, { passive: passive2 });
      var n = document_listeners.get(event_name);
      if (n === void 0) {
        document.addEventListener(event_name, handle_event_propagation, { passive: passive2 });
        document_listeners.set(event_name, 1);
      } else {
        document_listeners.set(event_name, n + 1);
      }
    }
  };
  event_handle(array_from(all_registered_events));
  root_event_handles.add(event_handle);
  var component2 = void 0;
  var unmount3 = component_root(() => {
    var anchor_node = anchor ?? target.appendChild(create_text());
    boundary(
      /** @type {TemplateNode} */
      anchor_node,
      {
        pending: () => {
        }
      },
      (anchor_node2) => {
        if (context2) {
          push({});
          var ctx = (
            /** @type {ComponentContext} */
            component_context
          );
          ctx.c = context2;
        }
        if (events) {
          props.$$events = events;
        }
        if (hydrating) {
          assign_nodes(
            /** @type {TemplateNode} */
            anchor_node2,
            null
          );
        }
        should_intro = intro;
        component2 = Component(anchor_node2, props) || {};
        should_intro = true;
        if (hydrating) {
          active_effect.nodes_end = hydrate_node;
          if (hydrate_node === null || hydrate_node.nodeType !== COMMENT_NODE || /** @type {Comment} */
          hydrate_node.data !== HYDRATION_END) {
            hydration_mismatch();
            throw HYDRATION_ERROR;
          }
        }
        if (context2) {
          pop();
        }
      }
    );
    return () => {
      for (var event_name of registered_events) {
        target.removeEventListener(event_name, handle_event_propagation);
        var n = (
          /** @type {number} */
          document_listeners.get(event_name)
        );
        if (--n === 0) {
          document.removeEventListener(event_name, handle_event_propagation);
          document_listeners.delete(event_name);
        } else {
          document_listeners.set(event_name, n);
        }
      }
      root_event_handles.delete(event_handle);
      if (anchor_node !== anchor) {
        anchor_node.parentNode?.removeChild(anchor_node);
      }
    };
  });
  mounted_components.set(component2, unmount3);
  return component2;
}
function unmount(component2, options) {
  const fn = mounted_components.get(component2);
  if (fn) {
    mounted_components.delete(component2);
    return fn(options);
  }
  if (true_default) {
    if (STATE_SYMBOL in component2) {
      state_proxy_unmount();
    } else {
      lifecycle_double_unmount();
    }
  }
  return Promise.resolve();
}
var should_intro, document_listeners, mounted_components;
var init_render = __esm({
  "node_modules/svelte/src/internal/client/render.js"() {
    init_esm_env();
    init_operations();
    init_constants();
    init_runtime();
    init_context();
    init_effects();
    init_hydration();
    init_utils();
    init_events();
    init_warnings();
    init_errors2();
    init_template();
    init_utils2();
    init_constants2();
    init_boundary();
    should_intro = true;
    document_listeners = /* @__PURE__ */ new Map();
    mounted_components = /* @__PURE__ */ new WeakMap();
  }
});

// node_modules/svelte/src/internal/client/dev/hmr.js
function hmr(original, get_source) {
  function wrapper(anchor, props) {
    let instance = {};
    let effect2;
    let ran = false;
    block(() => {
      const source2 = get_source();
      const component2 = get(source2);
      if (effect2) {
        for (var k in instance) delete instance[k];
        destroy_effect(effect2);
      }
      effect2 = branch(() => {
        if (ran) set_should_intro(false);
        Object.defineProperties(
          instance,
          Object.getOwnPropertyDescriptors(
            // @ts-expect-error
            new.target ? new component2(anchor, props) : component2(anchor, props)
          )
        );
        if (ran) set_should_intro(true);
      });
    }, EFFECT_TRANSPARENT);
    ran = true;
    if (hydrating) {
      anchor = hydrate_node;
    }
    return instance;
  }
  wrapper[FILENAME] = original[FILENAME];
  wrapper[HMR] = {
    // When we accept an update, we set the original source to the new component
    original,
    // The `get_source` parameter reads `wrapper[HMR].source`, but in the `accept`
    // function we always replace it with `previous[HMR].source`, which in practice
    // means we only ever update the original
    source: source(original)
  };
  return wrapper;
}
var init_hmr = __esm({
  "node_modules/svelte/src/internal/client/dev/hmr.js"() {
    init_constants();
    init_constants2();
    init_hydration();
    init_effects();
    init_sources();
    init_render();
    init_runtime();
  }
});

// node_modules/svelte/src/internal/client/dev/ownership.js
function create_ownership_validator(props) {
  const component2 = component_context?.function;
  const parent = component_context?.p?.function;
  return {
    /**
     * @param {string} prop
     * @param {any[]} path
     * @param {any} result
     * @param {number} line
     * @param {number} column
     */
    mutation: (prop2, path, result, line, column) => {
      const name = path[0];
      if (is_bound_or_unset(props, name) || !parent) {
        return result;
      }
      let value = props;
      for (let i = 0; i < path.length - 1; i++) {
        value = value[path[i]];
        if (!value?.[STATE_SYMBOL]) {
          return result;
        }
      }
      const location = sanitize_location(`${component2[FILENAME]}:${line}:${column}`);
      ownership_invalid_mutation(name, location, prop2, parent[FILENAME]);
      return result;
    },
    /**
     * @param {any} key
     * @param {any} child_component
     * @param {() => any} value
     */
    binding: (key2, child_component, value) => {
      if (!is_bound_or_unset(props, key2) && parent && value()?.[STATE_SYMBOL]) {
        ownership_invalid_binding(
          component2[FILENAME],
          key2,
          child_component[FILENAME],
          parent[FILENAME]
        );
      }
    }
  };
}
function is_bound_or_unset(props, prop_name) {
  const is_entry_props = STATE_SYMBOL in props || LEGACY_PROPS in props;
  return !!get_descriptor(props, prop_name)?.set || is_entry_props && prop_name in props || !(prop_name in props);
}
var init_ownership = __esm({
  "node_modules/svelte/src/internal/client/dev/ownership.js"() {
    init_utils();
    init_constants2();
    init_constants();
    init_context();
    init_warnings();
    init_utils2();
  }
});

// node_modules/svelte/src/internal/client/dev/legacy.js
function check_target(target) {
  if (target) {
    component_api_invalid_new(target[FILENAME] ?? "a component", target.name);
  }
}
function legacy_api() {
  const component2 = component_context?.function;
  function error(method) {
    component_api_changed(method, component2[FILENAME]);
  }
  return {
    $destroy: () => error("$destroy()"),
    $on: () => error("$on(...)"),
    $set: () => error("$set(...)")
  };
}
var init_legacy2 = __esm({
  "node_modules/svelte/src/internal/client/dev/legacy.js"() {
    init_errors2();
    init_context();
    init_constants();
  }
});

// node_modules/svelte/src/internal/client/dev/inspect.js
function inspect(get_value, inspector, show_stack = false) {
  validate_effect("$inspect");
  let initial = true;
  let error = (
    /** @type {any} */
    UNINITIALIZED
  );
  eager_effect(() => {
    try {
      var value = get_value();
    } catch (e) {
      error = e;
      return;
    }
    var snap = snapshot(value, true, true);
    untrack(() => {
      if (show_stack) {
        inspector(...snap);
        if (!initial) {
          const stack2 = get_error("$inspect(...)");
          if (stack2) {
            console.groupCollapsed("stack trace");
            console.log(stack2);
            console.groupEnd();
          }
        }
      } else {
        inspector(initial ? "init" : "update", ...snap);
      }
    });
    initial = false;
  });
  render_effect(() => {
    try {
      get_value();
    } catch {
    }
    if (error !== UNINITIALIZED) {
      console.error(error);
      error = UNINITIALIZED;
    }
  });
}
var init_inspect = __esm({
  "node_modules/svelte/src/internal/client/dev/inspect.js"() {
    init_constants();
    init_clone();
    init_effects();
    init_runtime();
    init_dev();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/async.js
function async(node, blockers = [], expressions = [], fn) {
  var boundary2 = get_boundary();
  var batch = (
    /** @type {Batch} */
    current_batch
  );
  var blocking = !boundary2.is_pending();
  boundary2.update_pending_count(1);
  batch.increment(blocking);
  var was_hydrating = hydrating;
  if (was_hydrating) {
    hydrate_next();
    var previous_hydrate_node = hydrate_node;
    var end = skip_nodes(false);
    set_hydrate_node(end);
  }
  flatten(blockers, [], expressions, (values) => {
    if (was_hydrating) {
      set_hydrating(true);
      set_hydrate_node(previous_hydrate_node);
    }
    try {
      for (const d of values) get(d);
      fn(node, ...values);
    } finally {
      if (was_hydrating) {
        set_hydrating(false);
      }
      boundary2.update_pending_count(-1);
      batch.decrement(blocking);
    }
  });
}
var init_async2 = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/async.js"() {
    init_async();
    init_batch();
    init_runtime();
    init_hydration();
    init_boundary();
  }
});

// node_modules/svelte/src/internal/client/dev/validation.js
function validate_snippet_args(anchor, ...args) {
  if (typeof anchor !== "object" || !(anchor instanceof Node)) {
    invalid_snippet_arguments();
  }
  for (let arg of args) {
    if (typeof arg !== "function") {
      invalid_snippet_arguments();
    }
  }
}
var init_validation = __esm({
  "node_modules/svelte/src/internal/client/dev/validation.js"() {
    init_errors2();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/branches.js
var BranchManager;
var init_branches = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/branches.js"() {
    init_batch();
    init_effects();
    init_hydration();
    init_operations();
    BranchManager = class {
      /** @type {TemplateNode} */
      anchor;
      /** @type {Map<Batch, Key>} */
      #batches = /* @__PURE__ */ new Map();
      /**
       * Map of keys to effects that are currently rendered in the DOM.
       * These effects are visible and actively part of the document tree.
       * Example:
       * ```
       * {#if condition}
       * 	foo
       * {:else}
       * 	bar
       * {/if}
       * ```
       * Can result in the entries `true->Effect` and `false->Effect`
       * @type {Map<Key, Effect>}
       */
      #onscreen = /* @__PURE__ */ new Map();
      /**
       * Similar to #onscreen with respect to the keys, but contains branches that are not yet
       * in the DOM, because their insertion is deferred.
       * @type {Map<Key, Branch>}
       */
      #offscreen = /* @__PURE__ */ new Map();
      /**
       * Keys of effects that are currently outroing
       * @type {Set<Key>}
       */
      #outroing = /* @__PURE__ */ new Set();
      /**
       * Whether to pause (i.e. outro) on change, or destroy immediately.
       * This is necessary for `<svelte:element>`
       */
      #transition = true;
      /**
       * @param {TemplateNode} anchor
       * @param {boolean} transition
       */
      constructor(anchor, transition2 = true) {
        this.anchor = anchor;
        this.#transition = transition2;
      }
      #commit = () => {
        var batch = (
          /** @type {Batch} */
          current_batch
        );
        if (!this.#batches.has(batch)) return;
        var key2 = (
          /** @type {Key} */
          this.#batches.get(batch)
        );
        var onscreen = this.#onscreen.get(key2);
        if (onscreen) {
          resume_effect(onscreen);
          this.#outroing.delete(key2);
        } else {
          var offscreen = this.#offscreen.get(key2);
          if (offscreen) {
            this.#onscreen.set(key2, offscreen.effect);
            this.#offscreen.delete(key2);
            offscreen.fragment.lastChild.remove();
            this.anchor.before(offscreen.fragment);
            onscreen = offscreen.effect;
          }
        }
        for (const [b, k] of this.#batches) {
          this.#batches.delete(b);
          if (b === batch) {
            break;
          }
          const offscreen2 = this.#offscreen.get(k);
          if (offscreen2) {
            destroy_effect(offscreen2.effect);
            this.#offscreen.delete(k);
          }
        }
        for (const [k, effect2] of this.#onscreen) {
          if (k === key2 || this.#outroing.has(k)) continue;
          const on_destroy = () => {
            const keys = Array.from(this.#batches.values());
            if (keys.includes(k)) {
              var fragment = document.createDocumentFragment();
              move_effect(effect2, fragment);
              fragment.append(create_text());
              this.#offscreen.set(k, { effect: effect2, fragment });
            } else {
              destroy_effect(effect2);
            }
            this.#outroing.delete(k);
            this.#onscreen.delete(k);
          };
          if (this.#transition || !onscreen) {
            this.#outroing.add(k);
            pause_effect(effect2, on_destroy, false);
          } else {
            on_destroy();
          }
        }
      };
      /**
       * @param {Batch} batch
       */
      #discard = (batch) => {
        this.#batches.delete(batch);
        const keys = Array.from(this.#batches.values());
        for (const [k, branch2] of this.#offscreen) {
          if (!keys.includes(k)) {
            destroy_effect(branch2.effect);
            this.#offscreen.delete(k);
          }
        }
      };
      /**
       *
       * @param {any} key
       * @param {null | ((target: TemplateNode) => void)} fn
       */
      ensure(key2, fn) {
        var batch = (
          /** @type {Batch} */
          current_batch
        );
        var defer = should_defer_append();
        if (fn && !this.#onscreen.has(key2) && !this.#offscreen.has(key2)) {
          if (defer) {
            var fragment = document.createDocumentFragment();
            var target = create_text();
            fragment.append(target);
            this.#offscreen.set(key2, {
              effect: branch(() => fn(target)),
              fragment
            });
          } else {
            this.#onscreen.set(
              key2,
              branch(() => fn(this.anchor))
            );
          }
        }
        this.#batches.set(batch, key2);
        if (defer) {
          for (const [k, effect2] of this.#onscreen) {
            if (k === key2) {
              batch.skipped_effects.delete(effect2);
            } else {
              batch.skipped_effects.add(effect2);
            }
          }
          for (const [k, branch2] of this.#offscreen) {
            if (k === key2) {
              batch.skipped_effects.delete(branch2.effect);
            } else {
              batch.skipped_effects.add(branch2.effect);
            }
          }
          batch.oncommit(this.#commit);
          batch.ondiscard(this.#discard);
        } else {
          if (hydrating) {
            this.anchor = hydrate_node;
          }
          this.#commit();
        }
      }
    };
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/await.js
function await_block(node, get_input, pending_fn, then_fn, catch_fn) {
  if (hydrating) {
    hydrate_next();
  }
  var runes = is_runes();
  var v = (
    /** @type {V} */
    UNINITIALIZED
  );
  var value = runes ? source(v) : mutable_source(v, false, false);
  var error = runes ? source(v) : mutable_source(v, false, false);
  var branches = new BranchManager(node);
  block(() => {
    var input = get_input();
    var destroyed = false;
    let mismatch = hydrating && is_promise(input) === (node.data === HYDRATION_START_ELSE);
    if (mismatch) {
      set_hydrate_node(skip_nodes());
      set_hydrating(false);
    }
    if (is_promise(input)) {
      var restore = capture();
      var resolved = false;
      const resolve = (fn) => {
        if (destroyed) return;
        resolved = true;
        restore(false);
        Batch.ensure();
        if (hydrating) {
          set_hydrating(false);
        }
        try {
          fn();
        } finally {
          unset_context();
          if (!is_flushing_sync) flushSync();
        }
      };
      input.then(
        (v2) => {
          resolve(() => {
            internal_set(value, v2);
            branches.ensure(THEN, then_fn && ((target) => then_fn(target, value)));
          });
        },
        (e) => {
          resolve(() => {
            internal_set(error, e);
            branches.ensure(THEN, catch_fn && ((target) => catch_fn(target, error)));
            if (!catch_fn) {
              throw error.v;
            }
          });
        }
      );
      if (hydrating) {
        branches.ensure(PENDING, pending_fn);
      } else {
        queue_micro_task(() => {
          if (!resolved) {
            resolve(() => {
              branches.ensure(PENDING, pending_fn);
            });
          }
        });
      }
    } else {
      internal_set(value, input);
      branches.ensure(THEN, then_fn && ((target) => then_fn(target, value)));
    }
    if (mismatch) {
      set_hydrating(true);
    }
    return () => {
      destroyed = true;
    };
  });
}
var PENDING, THEN;
var init_await = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/await.js"() {
    init_utils();
    init_effects();
    init_sources();
    init_hydration();
    init_task();
    init_constants();
    init_context();
    init_batch();
    init_branches();
    init_async();
    PENDING = 0;
    THEN = 1;
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/if.js
function if_block(node, fn, elseif = false) {
  if (hydrating) {
    hydrate_next();
  }
  var branches = new BranchManager(node);
  var flags2 = elseif ? EFFECT_TRANSPARENT : 0;
  function update_branch(condition, fn2) {
    if (hydrating) {
      const is_else = read_hydration_instruction(node) === HYDRATION_START_ELSE;
      if (condition === is_else) {
        var anchor = skip_nodes();
        set_hydrate_node(anchor);
        branches.anchor = anchor;
        set_hydrating(false);
        branches.ensure(condition, fn2);
        set_hydrating(true);
        return;
      }
    }
    branches.ensure(condition, fn2);
  }
  block(() => {
    var has_branch = false;
    fn((fn2, flag = true) => {
      has_branch = true;
      update_branch(flag, fn2);
    });
    if (!has_branch) {
      update_branch(false, null);
    }
  }, flags2);
}
var init_if = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/if.js"() {
    init_constants2();
    init_hydration();
    init_effects();
    init_constants();
    init_branches();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/key.js
function key(node, get_key, render_fn) {
  if (hydrating) {
    hydrate_next();
  }
  var branches = new BranchManager(node);
  var legacy = !is_runes();
  block(() => {
    var key2 = get_key();
    if (legacy && key2 !== null && typeof key2 === "object") {
      key2 = /** @type {V} */
      {};
    }
    branches.ensure(key2, render_fn);
  });
}
var init_key = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/key.js"() {
    init_context();
    init_effects();
    init_hydration();
    init_branches();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/css-props.js
function css_props(element2, get_styles) {
  if (hydrating) {
    set_hydrate_node(
      /** @type {TemplateNode} */
      get_first_child(element2)
    );
  }
  render_effect(() => {
    var styles = get_styles();
    for (var key2 in styles) {
      var value = styles[key2];
      if (value) {
        element2.style.setProperty(key2, value);
      } else {
        element2.style.removeProperty(key2);
      }
    }
  });
}
var init_css_props = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/css-props.js"() {
    init_effects();
    init_hydration();
    init_operations();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/html.js
function check_hash(element2, server_hash, value) {
  if (!server_hash || server_hash === hash(String(value ?? ""))) return;
  let location;
  const loc = element2.__svelte_meta?.loc;
  if (loc) {
    location = `near ${loc.file}:${loc.line}:${loc.column}`;
  } else if (dev_current_component_function?.[FILENAME]) {
    location = `in ${dev_current_component_function[FILENAME]}`;
  }
  hydration_html_changed(sanitize_location(location));
}
function html(node, get_value, svg = false, mathml = false, skip_warning = false) {
  var anchor = node;
  var value = "";
  template_effect(() => {
    var effect2 = (
      /** @type {Effect} */
      active_effect
    );
    if (value === (value = get_value() ?? "")) {
      if (hydrating) hydrate_next();
      return;
    }
    if (effect2.nodes_start !== null) {
      remove_effect_dom(
        effect2.nodes_start,
        /** @type {TemplateNode} */
        effect2.nodes_end
      );
      effect2.nodes_start = effect2.nodes_end = null;
    }
    if (value === "") return;
    if (hydrating) {
      var hash2 = (
        /** @type {Comment} */
        hydrate_node.data
      );
      var next2 = hydrate_next();
      var last = next2;
      while (next2 !== null && (next2.nodeType !== COMMENT_NODE || /** @type {Comment} */
      next2.data !== "")) {
        last = next2;
        next2 = /** @type {TemplateNode} */
        get_next_sibling(next2);
      }
      if (next2 === null) {
        hydration_mismatch();
        throw HYDRATION_ERROR;
      }
      if (true_default && !skip_warning) {
        check_hash(
          /** @type {Element} */
          next2.parentNode,
          hash2,
          value
        );
      }
      assign_nodes(hydrate_node, last);
      anchor = set_hydrate_node(next2);
      return;
    }
    var html3 = value + "";
    if (svg) html3 = `<svg>${html3}</svg>`;
    else if (mathml) html3 = `<math>${html3}</math>`;
    var node2 = create_fragment_from_html(html3);
    if (svg || mathml) {
      node2 = /** @type {Element} */
      get_first_child(node2);
    }
    assign_nodes(
      /** @type {TemplateNode} */
      get_first_child(node2),
      /** @type {TemplateNode} */
      node2.lastChild
    );
    if (svg || mathml) {
      while (get_first_child(node2)) {
        anchor.before(
          /** @type {Node} */
          get_first_child(node2)
        );
      }
    } else {
      anchor.before(node2);
    }
  });
}
var init_html = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/html.js"() {
    init_constants();
    init_effects();
    init_hydration();
    init_reconciler();
    init_template();
    init_warnings();
    init_utils2();
    init_esm_env();
    init_context();
    init_operations();
    init_runtime();
    init_constants2();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/slot.js
function slot(anchor, $$props, name, slot_props, fallback_fn) {
  if (hydrating) {
    hydrate_next();
  }
  var slot_fn = $$props.$$slots?.[name];
  var is_interop = false;
  if (slot_fn === true) {
    slot_fn = $$props[name === "default" ? "children" : name];
    is_interop = true;
  }
  if (slot_fn === void 0) {
    if (fallback_fn !== null) {
      fallback_fn(anchor);
    }
  } else {
    slot_fn(anchor, is_interop ? () => slot_props : slot_props);
  }
}
function sanitize_slots(props) {
  const sanitized = {};
  if (props.children) sanitized.default = true;
  for (const key2 in props.$$slots) {
    sanitized[key2] = true;
  }
  return sanitized;
}
var init_slot = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/slot.js"() {
    init_hydration();
  }
});

// node_modules/svelte/src/internal/shared/validate.js
function validate_void_dynamic_element(tag_fn) {
  const tag2 = tag_fn();
  if (tag2 && is_void(tag2)) {
    dynamic_void_element_content(tag2);
  }
}
function validate_dynamic_element_tag(tag_fn) {
  const tag2 = tag_fn();
  const is_string = typeof tag2 === "string";
  if (tag2 && !is_string) {
    svelte_element_invalid_this_value();
  }
}
function validate_store(store, name) {
  if (store != null && typeof store.subscribe !== "function") {
    store_invalid_shape(name);
  }
}
function prevent_snippet_stringification(fn) {
  fn.toString = () => {
    snippet_without_render_tag();
    return "";
  };
  return fn;
}
var init_validate = __esm({
  "node_modules/svelte/src/internal/shared/validate.js"() {
    init_utils2();
    init_warnings2();
    init_errors();
    init_errors();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/snippet.js
function snippet(node, get_snippet, ...args) {
  var branches = new BranchManager(node);
  block(() => {
    const snippet2 = get_snippet() ?? null;
    if (true_default && snippet2 == null) {
      invalid_snippet();
    }
    branches.ensure(snippet2, snippet2 && ((anchor) => snippet2(anchor, ...args)));
  }, EFFECT_TRANSPARENT);
}
function wrap_snippet(component2, fn) {
  const snippet2 = (node, ...args) => {
    var previous_component_function = dev_current_component_function;
    set_dev_current_component_function(component2);
    try {
      return fn(node, ...args);
    } finally {
      set_dev_current_component_function(previous_component_function);
    }
  };
  prevent_snippet_stringification(snippet2);
  return snippet2;
}
var init_snippet = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/snippet.js"() {
    init_constants2();
    init_effects();
    init_context();
    init_hydration();
    init_reconciler();
    init_template();
    init_warnings();
    init_errors2();
    init_esm_env();
    init_operations();
    init_validate();
    init_branches();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/svelte-component.js
function component(node, get_component, render_fn) {
  if (hydrating) {
    hydrate_next();
  }
  var branches = new BranchManager(node);
  block(() => {
    var component2 = get_component() ?? null;
    branches.ensure(component2, component2 && ((target) => render_fn(target, component2)));
  }, EFFECT_TRANSPARENT);
}
var init_svelte_component = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/svelte-component.js"() {
    init_constants2();
    init_effects();
    init_hydration();
    init_branches();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/svelte-element.js
function element(node, get_tag, is_svg, render_fn, get_namespace, location) {
  let was_hydrating = hydrating;
  if (hydrating) {
    hydrate_next();
  }
  var filename = true_default && location && component_context?.function[FILENAME];
  var element2 = null;
  if (hydrating && hydrate_node.nodeType === ELEMENT_NODE) {
    element2 = /** @type {Element} */
    hydrate_node;
    hydrate_next();
  }
  var anchor = (
    /** @type {TemplateNode} */
    hydrating ? hydrate_node : node
  );
  var each_item_block = current_each_item;
  var branches = new BranchManager(anchor, false);
  block(() => {
    const next_tag = get_tag() || null;
    var ns = get_namespace ? get_namespace() : is_svg || next_tag === "svg" ? NAMESPACE_SVG : null;
    if (next_tag === null) {
      branches.ensure(null, null);
      set_should_intro(true);
      return;
    }
    branches.ensure(next_tag, (anchor2) => {
      var previous_each_item = current_each_item;
      set_current_each_item(each_item_block);
      if (next_tag) {
        element2 = hydrating ? (
          /** @type {Element} */
          element2
        ) : ns ? document.createElementNS(ns, next_tag) : document.createElement(next_tag);
        if (true_default && location) {
          element2.__svelte_meta = {
            parent: dev_stack,
            loc: {
              file: filename,
              line: location[0],
              column: location[1]
            }
          };
        }
        assign_nodes(element2, element2);
        if (render_fn) {
          if (hydrating && is_raw_text_element(next_tag)) {
            element2.append(document.createComment(""));
          }
          var child_anchor = (
            /** @type {TemplateNode} */
            hydrating ? get_first_child(element2) : element2.appendChild(create_text())
          );
          if (hydrating) {
            if (child_anchor === null) {
              set_hydrating(false);
            } else {
              set_hydrate_node(child_anchor);
            }
          }
          render_fn(element2, child_anchor);
        }
        active_effect.nodes_end = element2;
        anchor2.before(element2);
      }
      set_current_each_item(previous_each_item);
      if (hydrating) {
        set_hydrate_node(anchor2);
      }
    });
    set_should_intro(true);
    return () => {
      if (next_tag) {
        set_should_intro(false);
      }
    };
  }, EFFECT_TRANSPARENT);
  teardown(() => {
    set_should_intro(true);
  });
  if (was_hydrating) {
    set_hydrating(true);
    set_hydrate_node(anchor);
  }
}
var init_svelte_element = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/svelte-element.js"() {
    init_constants();
    init_hydration();
    init_operations();
    init_effects();
    init_render();
    init_each();
    init_runtime();
    init_context();
    init_esm_env();
    init_constants2();
    init_template();
    init_utils2();
    init_branches();
  }
});

// node_modules/svelte/src/internal/client/dom/blocks/svelte-head.js
function head(hash2, render_fn) {
  let previous_hydrate_node = null;
  let was_hydrating = hydrating;
  var anchor;
  if (hydrating) {
    previous_hydrate_node = hydrate_node;
    var head_anchor = (
      /** @type {TemplateNode} */
      get_first_child(document.head)
    );
    while (head_anchor !== null && (head_anchor.nodeType !== COMMENT_NODE || /** @type {Comment} */
    head_anchor.data !== hash2)) {
      head_anchor = /** @type {TemplateNode} */
      get_next_sibling(head_anchor);
    }
    if (head_anchor === null) {
      set_hydrating(false);
    } else {
      var start = (
        /** @type {TemplateNode} */
        get_next_sibling(head_anchor)
      );
      head_anchor.remove();
      set_hydrate_node(start);
    }
  }
  if (!hydrating) {
    anchor = document.head.appendChild(create_text());
  }
  try {
    block(() => render_fn(anchor), HEAD_EFFECT);
  } finally {
    if (was_hydrating) {
      set_hydrating(true);
      set_hydrate_node(
        /** @type {TemplateNode} */
        previous_hydrate_node
      );
    }
  }
}
var init_svelte_head = __esm({
  "node_modules/svelte/src/internal/client/dom/blocks/svelte-head.js"() {
    init_hydration();
    init_operations();
    init_effects();
    init_constants2();
  }
});

// node_modules/svelte/src/internal/client/dom/css.js
function append_styles2(anchor, css) {
  effect(() => {
    var root = anchor.getRootNode();
    var target = (
      /** @type {ShadowRoot} */
      root.host ? (
        /** @type {ShadowRoot} */
        root
      ) : (
        /** @type {Document} */
        root.head ?? /** @type {Document} */
        root.ownerDocument.head
      )
    );
    if (!target.querySelector("#" + css.hash)) {
      const style = document.createElement("style");
      style.id = css.hash;
      style.textContent = css.code;
      target.appendChild(style);
      if (true_default) {
        register_style(css.hash, style);
      }
    }
  });
}
var init_css2 = __esm({
  "node_modules/svelte/src/internal/client/dom/css.js"() {
    init_esm_env();
    init_css();
    init_effects();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/actions.js
function action(dom, action2, get_value) {
  effect(() => {
    var payload = untrack(() => action2(dom, get_value?.()) || {});
    if (get_value && payload?.update) {
      var inited = false;
      var prev = (
        /** @type {any} */
        {}
      );
      render_effect(() => {
        var value = get_value();
        deep_read_state(value);
        if (inited && safe_not_equal(prev, value)) {
          prev = value;
          payload.update(value);
        }
      });
      inited = true;
    }
    if (payload?.destroy) {
      return () => (
        /** @type {Function} */
        payload.destroy()
      );
    }
  });
}
var init_actions = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/actions.js"() {
    init_effects();
    init_equality();
    init_runtime();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/attachments.js
function attach(node, get_fn) {
  var fn = void 0;
  var e;
  managed(() => {
    if (fn !== (fn = get_fn())) {
      if (e) {
        destroy_effect(e);
        e = null;
      }
      if (fn) {
        e = branch(() => {
          effect(() => (
            /** @type {(node: Element) => void} */
            fn(node)
          ));
        });
      }
    }
  });
}
var init_attachments2 = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/attachments.js"() {
    init_effects();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/class.js
function set_class(dom, is_html, value, hash2, prev_classes, next_classes) {
  var prev = dom.__className;
  if (hydrating || prev !== value || prev === void 0) {
    var next_class_name = to_class(value, hash2, next_classes);
    if (!hydrating || next_class_name !== dom.getAttribute("class")) {
      if (next_class_name == null) {
        dom.removeAttribute("class");
      } else if (is_html) {
        dom.className = next_class_name;
      } else {
        dom.setAttribute("class", next_class_name);
      }
    }
    dom.__className = value;
  } else if (next_classes && prev_classes !== next_classes) {
    for (var key2 in next_classes) {
      var is_present = !!next_classes[key2];
      if (prev_classes == null || is_present !== !!prev_classes[key2]) {
        dom.classList.toggle(key2, is_present);
      }
    }
  }
  return next_classes;
}
var init_class = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/class.js"() {
    init_attributes();
    init_hydration();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/style.js
function update_styles(dom, prev = {}, next2, priority) {
  for (var key2 in next2) {
    var value = next2[key2];
    if (prev[key2] !== value) {
      if (next2[key2] == null) {
        dom.style.removeProperty(key2);
      } else {
        dom.style.setProperty(key2, value, priority);
      }
    }
  }
}
function set_style(dom, value, prev_styles, next_styles) {
  var prev = dom.__style;
  if (hydrating || prev !== value) {
    var next_style_attr = to_style(value, next_styles);
    if (!hydrating || next_style_attr !== dom.getAttribute("style")) {
      if (next_style_attr == null) {
        dom.removeAttribute("style");
      } else {
        dom.style.cssText = next_style_attr;
      }
    }
    dom.__style = value;
  } else if (next_styles) {
    if (Array.isArray(next_styles)) {
      update_styles(dom, prev_styles?.[0], next_styles[0]);
      update_styles(dom, prev_styles?.[1], next_styles[1], "important");
    } else {
      update_styles(dom, prev_styles, next_styles);
    }
  }
  return next_styles;
}
var init_style = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/style.js"() {
    init_attributes();
    init_hydration();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/select.js
function select_option(select, value, mounting = false) {
  if (select.multiple) {
    if (value == void 0) {
      return;
    }
    if (!is_array(value)) {
      return select_multiple_invalid_value();
    }
    for (var option of select.options) {
      option.selected = value.includes(get_option_value(option));
    }
    return;
  }
  for (option of select.options) {
    var option_value = get_option_value(option);
    if (is(option_value, value)) {
      option.selected = true;
      return;
    }
  }
  if (!mounting || value !== void 0) {
    select.selectedIndex = -1;
  }
}
function init_select2(select) {
  var observer = new MutationObserver(() => {
    select_option(select, select.__value);
  });
  observer.observe(select, {
    // Listen to option element changes
    childList: true,
    subtree: true,
    // because of <optgroup>
    // Listen to option element value attribute changes
    // (doesn't get notified of select value changes,
    // because that property is not reflected as an attribute)
    attributes: true,
    attributeFilter: ["value"]
  });
  teardown(() => {
    observer.disconnect();
  });
}
function bind_select_value(select, get3, set2 = get3) {
  var batches2 = /* @__PURE__ */ new WeakSet();
  var mounting = true;
  listen_to_event_and_reset_event(select, "change", (is_reset) => {
    var query = is_reset ? "[selected]" : ":checked";
    var value;
    if (select.multiple) {
      value = [].map.call(select.querySelectorAll(query), get_option_value);
    } else {
      var selected_option = select.querySelector(query) ?? // will fall back to first non-disabled option if no option is selected
      select.querySelector("option:not([disabled])");
      value = selected_option && get_option_value(selected_option);
    }
    set2(value);
    if (current_batch !== null) {
      batches2.add(current_batch);
    }
  });
  effect(() => {
    var value = get3();
    if (select === document.activeElement) {
      var batch = (
        /** @type {Batch} */
        previous_batch ?? current_batch
      );
      if (batches2.has(batch)) {
        return;
      }
    }
    select_option(select, value, mounting);
    if (mounting && value === void 0) {
      var selected_option = select.querySelector(":checked");
      if (selected_option !== null) {
        value = get_option_value(selected_option);
        set2(value);
      }
    }
    select.__value = value;
    mounting = false;
  });
  init_select2(select);
}
function get_option_value(option) {
  if ("__value" in option) {
    return option.__value;
  } else {
    return option.value;
  }
}
var init_select = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/select.js"() {
    init_effects();
    init_shared();
    init_proxy();
    init_utils();
    init_warnings();
    init_batch();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/attributes.js
function remove_input_defaults(input) {
  if (!hydrating) return;
  var already_removed = false;
  var remove_defaults = () => {
    if (already_removed) return;
    already_removed = true;
    if (input.hasAttribute("value")) {
      var value = input.value;
      set_attribute2(input, "value", null);
      input.value = value;
    }
    if (input.hasAttribute("checked")) {
      var checked = input.checked;
      set_attribute2(input, "checked", null);
      input.checked = checked;
    }
  };
  input.__on_r = remove_defaults;
  queue_micro_task(remove_defaults);
  add_form_reset_listener();
}
function set_value(element2, value) {
  var attributes2 = get_attributes(element2);
  if (attributes2.value === (attributes2.value = // treat null and undefined the same for the initial value
  value ?? void 0) || // @ts-expect-error
  // `progress` elements always need their value set when it's `0`
  element2.value === value && (value !== 0 || element2.nodeName !== "PROGRESS")) {
    return;
  }
  element2.value = value ?? "";
}
function set_checked(element2, checked) {
  var attributes2 = get_attributes(element2);
  if (attributes2.checked === (attributes2.checked = // treat null and undefined the same for the initial value
  checked ?? void 0)) {
    return;
  }
  element2.checked = checked;
}
function set_selected(element2, selected) {
  if (selected) {
    if (!element2.hasAttribute("selected")) {
      element2.setAttribute("selected", "");
    }
  } else {
    element2.removeAttribute("selected");
  }
}
function set_default_checked(element2, checked) {
  const existing_value = element2.checked;
  element2.defaultChecked = checked;
  element2.checked = existing_value;
}
function set_default_value(element2, value) {
  const existing_value = element2.value;
  element2.defaultValue = value;
  element2.value = existing_value;
}
function set_attribute2(element2, attribute, value, skip_warning) {
  var attributes2 = get_attributes(element2);
  if (hydrating) {
    attributes2[attribute] = element2.getAttribute(attribute);
    if (attribute === "src" || attribute === "srcset" || attribute === "href" && element2.nodeName === "LINK") {
      if (!skip_warning) {
        check_src_in_dev_hydration(element2, attribute, value ?? "");
      }
      return;
    }
  }
  if (attributes2[attribute] === (attributes2[attribute] = value)) return;
  if (attribute === "loading") {
    element2[LOADING_ATTR_SYMBOL] = value;
  }
  if (value == null) {
    element2.removeAttribute(attribute);
  } else if (typeof value !== "string" && get_setters(element2).includes(attribute)) {
    element2[attribute] = value;
  } else {
    element2.setAttribute(attribute, value);
  }
}
function set_xlink_attribute(dom, attribute, value) {
  dom.setAttributeNS("http://www.w3.org/1999/xlink", attribute, value);
}
function set_custom_element_data(node, prop2, value) {
  var previous_reaction = active_reaction;
  var previous_effect = active_effect;
  let was_hydrating = hydrating;
  if (hydrating) {
    set_hydrating(false);
  }
  set_active_reaction(null);
  set_active_effect(null);
  try {
    if (
      // `style` should use `set_attribute` rather than the setter
      prop2 !== "style" && // Don't compute setters for custom elements while they aren't registered yet,
      // because during their upgrade/instantiation they might add more setters.
      // Instead, fall back to a simple "an object, then set as property" heuristic.
      (setters_cache.has(node.getAttribute("is") || node.nodeName) || // customElements may not be available in browser extension contexts
      !customElements || customElements.get(node.getAttribute("is") || node.tagName.toLowerCase()) ? get_setters(node).includes(prop2) : value && typeof value === "object")
    ) {
      node[prop2] = value;
    } else {
      set_attribute2(node, prop2, value == null ? value : String(value));
    }
  } finally {
    set_active_reaction(previous_reaction);
    set_active_effect(previous_effect);
    if (was_hydrating) {
      set_hydrating(true);
    }
  }
}
function set_attributes(element2, prev, next2, css_hash, should_remove_defaults = false, skip_warning = false) {
  if (hydrating && should_remove_defaults && element2.tagName === "INPUT") {
    var input = (
      /** @type {HTMLInputElement} */
      element2
    );
    var attribute = input.type === "checkbox" ? "defaultChecked" : "defaultValue";
    if (!(attribute in next2)) {
      remove_input_defaults(input);
    }
  }
  var attributes2 = get_attributes(element2);
  var is_custom_element = attributes2[IS_CUSTOM_ELEMENT];
  var preserve_attribute_case = !attributes2[IS_HTML];
  let is_hydrating_custom_element = hydrating && is_custom_element;
  if (is_hydrating_custom_element) {
    set_hydrating(false);
  }
  var current = prev || {};
  var is_option_element = element2.tagName === "OPTION";
  for (var key2 in prev) {
    if (!(key2 in next2)) {
      next2[key2] = null;
    }
  }
  if (next2.class) {
    next2.class = clsx2(next2.class);
  } else if (css_hash || next2[CLASS]) {
    next2.class = null;
  }
  if (next2[STYLE]) {
    next2.style ??= null;
  }
  var setters = get_setters(element2);
  for (const key3 in next2) {
    let value = next2[key3];
    if (is_option_element && key3 === "value" && value == null) {
      element2.value = element2.__value = "";
      current[key3] = value;
      continue;
    }
    if (key3 === "class") {
      var is_html = element2.namespaceURI === "http://www.w3.org/1999/xhtml";
      set_class(element2, is_html, value, css_hash, prev?.[CLASS], next2[CLASS]);
      current[key3] = value;
      current[CLASS] = next2[CLASS];
      continue;
    }
    if (key3 === "style") {
      set_style(element2, value, prev?.[STYLE], next2[STYLE]);
      current[key3] = value;
      current[STYLE] = next2[STYLE];
      continue;
    }
    var prev_value = current[key3];
    if (value === prev_value && !(value === void 0 && element2.hasAttribute(key3))) {
      continue;
    }
    current[key3] = value;
    var prefix = key3[0] + key3[1];
    if (prefix === "$$") continue;
    if (prefix === "on") {
      const opts = {};
      const event_handle_key = "$$" + key3;
      let event_name = key3.slice(2);
      var delegated = can_delegate_event(event_name);
      if (is_capture_event(event_name)) {
        event_name = event_name.slice(0, -7);
        opts.capture = true;
      }
      if (!delegated && prev_value) {
        if (value != null) continue;
        element2.removeEventListener(event_name, current[event_handle_key], opts);
        current[event_handle_key] = null;
      }
      if (value != null) {
        if (!delegated) {
          let handle = function(evt) {
            current[key3].call(this, evt);
          };
          current[event_handle_key] = create_event(event_name, element2, handle, opts);
        } else {
          element2[`__${event_name}`] = value;
          delegate([event_name]);
        }
      } else if (delegated) {
        element2[`__${event_name}`] = void 0;
      }
    } else if (key3 === "style") {
      set_attribute2(element2, key3, value);
    } else if (key3 === "autofocus") {
      autofocus(
        /** @type {HTMLElement} */
        element2,
        Boolean(value)
      );
    } else if (!is_custom_element && (key3 === "__value" || key3 === "value" && value != null)) {
      element2.value = element2.__value = value;
    } else if (key3 === "selected" && is_option_element) {
      set_selected(
        /** @type {HTMLOptionElement} */
        element2,
        value
      );
    } else {
      var name = key3;
      if (!preserve_attribute_case) {
        name = normalize_attribute(name);
      }
      var is_default = name === "defaultValue" || name === "defaultChecked";
      if (value == null && !is_custom_element && !is_default) {
        attributes2[key3] = null;
        if (name === "value" || name === "checked") {
          let input2 = (
            /** @type {HTMLInputElement} */
            element2
          );
          const use_default = prev === void 0;
          if (name === "value") {
            let previous = input2.defaultValue;
            input2.removeAttribute(name);
            input2.defaultValue = previous;
            input2.value = input2.__value = use_default ? previous : null;
          } else {
            let previous = input2.defaultChecked;
            input2.removeAttribute(name);
            input2.defaultChecked = previous;
            input2.checked = use_default ? previous : false;
          }
        } else {
          element2.removeAttribute(key3);
        }
      } else if (is_default || setters.includes(name) && (is_custom_element || typeof value !== "string")) {
        element2[name] = value;
        if (name in attributes2) attributes2[name] = UNINITIALIZED;
      } else if (typeof value !== "function") {
        set_attribute2(element2, name, value, skip_warning);
      }
    }
  }
  if (is_hydrating_custom_element) {
    set_hydrating(true);
  }
  return current;
}
function attribute_effect(element2, fn, sync = [], async2 = [], blockers = [], css_hash, should_remove_defaults = false, skip_warning = false) {
  flatten(blockers, sync, async2, (values) => {
    var prev = void 0;
    var effects = {};
    var is_select = element2.nodeName === "SELECT";
    var inited = false;
    managed(() => {
      var next2 = fn(...values.map(get));
      var current = set_attributes(
        element2,
        prev,
        next2,
        css_hash,
        should_remove_defaults,
        skip_warning
      );
      if (inited && is_select && "value" in next2) {
        select_option(
          /** @type {HTMLSelectElement} */
          element2,
          next2.value
        );
      }
      for (let symbol of Object.getOwnPropertySymbols(effects)) {
        if (!next2[symbol]) destroy_effect(effects[symbol]);
      }
      for (let symbol of Object.getOwnPropertySymbols(next2)) {
        var n = next2[symbol];
        if (symbol.description === ATTACHMENT_KEY && (!prev || n !== prev[symbol])) {
          if (effects[symbol]) destroy_effect(effects[symbol]);
          effects[symbol] = branch(() => attach(element2, () => n));
        }
        current[symbol] = n;
      }
      prev = current;
    });
    if (is_select) {
      var select = (
        /** @type {HTMLSelectElement} */
        element2
      );
      effect(() => {
        select_option(
          select,
          /** @type {Record<string | symbol, any>} */
          prev.value,
          true
        );
        init_select2(select);
      });
    }
    inited = true;
  });
}
function get_attributes(element2) {
  return (
    /** @type {Record<string | symbol, unknown>} **/
    // @ts-expect-error
    element2.__attributes ??= {
      [IS_CUSTOM_ELEMENT]: element2.nodeName.includes("-"),
      [IS_HTML]: element2.namespaceURI === NAMESPACE_HTML
    }
  );
}
function get_setters(element2) {
  var cache_key = element2.getAttribute("is") || element2.nodeName;
  var setters = setters_cache.get(cache_key);
  if (setters) return setters;
  setters_cache.set(cache_key, setters = []);
  var descriptors;
  var proto = element2;
  var element_proto = Element.prototype;
  while (element_proto !== proto) {
    descriptors = get_descriptors(proto);
    for (var key2 in descriptors) {
      if (descriptors[key2].set) {
        setters.push(key2);
      }
    }
    proto = get_prototype_of(proto);
  }
  return setters;
}
function check_src_in_dev_hydration(element2, attribute, value) {
  if (!true_default) return;
  if (attribute === "srcset" && srcset_url_equal(element2, value)) return;
  if (src_url_equal(element2.getAttribute(attribute) ?? "", value)) return;
  hydration_attribute_changed(
    attribute,
    element2.outerHTML.replace(element2.innerHTML, element2.innerHTML && "..."),
    String(value)
  );
}
function src_url_equal(element_src, url) {
  if (element_src === url) return true;
  return new URL(element_src, document.baseURI).href === new URL(url, document.baseURI).href;
}
function split_srcset(srcset) {
  return srcset.split(",").map((src) => src.trim().split(" ").filter(Boolean));
}
function srcset_url_equal(element2, srcset) {
  var element_urls = split_srcset(element2.srcset);
  var urls = split_srcset(srcset);
  return urls.length === element_urls.length && urls.every(
    ([url, width], i) => width === element_urls[i][1] && // We need to test both ways because Vite will create an a full URL with
    // `new URL(asset, import.meta.url).href` for the client when `base: './'`, and the
    // relative URLs inside srcset are not automatically resolved to absolute URLs by
    // browsers (in contrast to img.src). This means both SSR and DOM code could
    // contain relative or absolute URLs.
    (src_url_equal(element_urls[i][0], url) || src_url_equal(url, element_urls[i][0]))
  );
}
var CLASS, STYLE, IS_CUSTOM_ELEMENT, IS_HTML, setters_cache;
var init_attributes2 = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/attributes.js"() {
    init_esm_env();
    init_hydration();
    init_utils();
    init_events();
    init_misc();
    init_warnings();
    init_constants2();
    init_task();
    init_utils2();
    init_runtime();
    init_attachments2();
    init_attributes();
    init_class();
    init_style();
    init_constants();
    init_effects();
    init_select();
    init_async();
    CLASS = Symbol("class");
    STYLE = Symbol("style");
    IS_CUSTOM_ELEMENT = Symbol("is custom element");
    IS_HTML = Symbol("is html");
    setters_cache = /* @__PURE__ */ new Map();
  }
});

// node_modules/svelte/src/internal/client/timing.js
var now, raf;
var init_timing = __esm({
  "node_modules/svelte/src/internal/client/timing.js"() {
    init_utils();
    init_esm_env();
    now = false_default ? () => performance.now() : () => Date.now();
    raf = {
      // don't access requestAnimationFrame eagerly outside method
      // this allows basic testing of user code without JSDOM
      // bunder will eval and remove ternary when the user's app is built
      tick: (
        /** @param {any} _ */
        (_) => (false_default ? requestAnimationFrame : noop)(_)
      ),
      now: () => now(),
      tasks: /* @__PURE__ */ new Set()
    };
  }
});

// node_modules/svelte/src/internal/client/loop.js
function run_tasks() {
  const now2 = raf.now();
  raf.tasks.forEach((task) => {
    if (!task.c(now2)) {
      raf.tasks.delete(task);
      task.f();
    }
  });
  if (raf.tasks.size !== 0) {
    raf.tick(run_tasks);
  }
}
function loop(callback) {
  let task;
  if (raf.tasks.size === 0) {
    raf.tick(run_tasks);
  }
  return {
    promise: new Promise((fulfill) => {
      raf.tasks.add(task = { c: callback, f: fulfill });
    }),
    abort() {
      raf.tasks.delete(task);
    }
  };
}
var init_loop = __esm({
  "node_modules/svelte/src/internal/client/loop.js"() {
    init_timing();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/transitions.js
function dispatch_event(element2, type) {
  without_reactive_context(() => {
    element2.dispatchEvent(new CustomEvent(type));
  });
}
function css_property_to_camelcase(style) {
  if (style === "float") return "cssFloat";
  if (style === "offset") return "cssOffset";
  if (style.startsWith("--")) return style;
  const parts = style.split("-");
  if (parts.length === 1) return parts[0];
  return parts[0] + parts.slice(1).map(
    /** @param {any} word */
    (word) => word[0].toUpperCase() + word.slice(1)
  ).join("");
}
function css_to_keyframe(css) {
  const keyframe = {};
  const parts = css.split(";");
  for (const part of parts) {
    const [property, value] = part.split(":");
    if (!property || value === void 0) break;
    const formatted_property = css_property_to_camelcase(property.trim());
    keyframe[formatted_property] = value.trim();
  }
  return keyframe;
}
function animation(element2, get_fn, get_params) {
  var item = (
    /** @type {EachItem} */
    current_each_item
  );
  var from;
  var to;
  var animation2;
  var original_styles = null;
  item.a ??= {
    element: element2,
    measure() {
      from = this.element.getBoundingClientRect();
    },
    apply() {
      animation2?.abort();
      to = this.element.getBoundingClientRect();
      if (from.left !== to.left || from.right !== to.right || from.top !== to.top || from.bottom !== to.bottom) {
        const options = get_fn()(this.element, { from, to }, get_params?.());
        animation2 = animate(this.element, options, void 0, 1, () => {
          animation2?.abort();
          animation2 = void 0;
        });
      }
    },
    fix() {
      if (element2.getAnimations().length) return;
      var { position, width, height } = getComputedStyle(element2);
      if (position !== "absolute" && position !== "fixed") {
        var style = (
          /** @type {HTMLElement | SVGElement} */
          element2.style
        );
        original_styles = {
          position: style.position,
          width: style.width,
          height: style.height,
          transform: style.transform
        };
        style.position = "absolute";
        style.width = width;
        style.height = height;
        var to2 = element2.getBoundingClientRect();
        if (from.left !== to2.left || from.top !== to2.top) {
          var transform = `translate(${from.left - to2.left}px, ${from.top - to2.top}px)`;
          style.transform = style.transform ? `${style.transform} ${transform}` : transform;
        }
      }
    },
    unfix() {
      if (original_styles) {
        var style = (
          /** @type {HTMLElement | SVGElement} */
          element2.style
        );
        style.position = original_styles.position;
        style.width = original_styles.width;
        style.height = original_styles.height;
        style.transform = original_styles.transform;
      }
    }
  };
  item.a.element = element2;
}
function transition(flags2, element2, get_fn, get_params) {
  var is_intro = (flags2 & TRANSITION_IN) !== 0;
  var is_outro = (flags2 & TRANSITION_OUT) !== 0;
  var is_both = is_intro && is_outro;
  var is_global = (flags2 & TRANSITION_GLOBAL) !== 0;
  var direction = is_both ? "both" : is_intro ? "in" : "out";
  var current_options;
  var inert = element2.inert;
  var overflow = element2.style.overflow;
  var intro;
  var outro;
  function get_options() {
    return without_reactive_context(() => {
      return current_options ??= get_fn()(element2, get_params?.() ?? /** @type {P} */
      {}, {
        direction
      });
    });
  }
  var transition2 = {
    is_global,
    in() {
      element2.inert = inert;
      if (!is_intro) {
        outro?.abort();
        outro?.reset?.();
        return;
      }
      if (!is_outro) {
        intro?.abort();
      }
      dispatch_event(element2, "introstart");
      intro = animate(element2, get_options(), outro, 1, () => {
        dispatch_event(element2, "introend");
        intro?.abort();
        intro = current_options = void 0;
        element2.style.overflow = overflow;
      });
    },
    out(fn) {
      if (!is_outro) {
        fn?.();
        current_options = void 0;
        return;
      }
      element2.inert = true;
      dispatch_event(element2, "outrostart");
      outro = animate(element2, get_options(), intro, 0, () => {
        dispatch_event(element2, "outroend");
        fn?.();
      });
    },
    stop: () => {
      intro?.abort();
      outro?.abort();
    }
  };
  var e = (
    /** @type {Effect} */
    active_effect
  );
  (e.transitions ??= []).push(transition2);
  if (is_intro && should_intro) {
    var run3 = is_global;
    if (!run3) {
      var block2 = (
        /** @type {Effect | null} */
        e.parent
      );
      while (block2 && (block2.f & EFFECT_TRANSPARENT) !== 0) {
        while (block2 = block2.parent) {
          if ((block2.f & BLOCK_EFFECT) !== 0) break;
        }
      }
      run3 = !block2 || (block2.f & EFFECT_RAN) !== 0;
    }
    if (run3) {
      effect(() => {
        untrack(() => transition2.in());
      });
    }
  }
}
function animate(element2, options, counterpart, t2, on_finish) {
  var is_intro = t2 === 1;
  if (is_function(options)) {
    var a;
    var aborted2 = false;
    queue_micro_task(() => {
      if (aborted2) return;
      var o = options({ direction: is_intro ? "in" : "out" });
      a = animate(element2, o, counterpart, t2, on_finish);
    });
    return {
      abort: () => {
        aborted2 = true;
        a?.abort();
      },
      deactivate: () => a.deactivate(),
      reset: () => a.reset(),
      t: () => a.t()
    };
  }
  counterpart?.deactivate();
  if (!options?.duration) {
    on_finish();
    return {
      abort: noop,
      deactivate: noop,
      reset: noop,
      t: () => t2
    };
  }
  const { delay = 0, css, tick: tick3, easing = linear } = options;
  var keyframes = [];
  if (is_intro && counterpart === void 0) {
    if (tick3) {
      tick3(0, 1);
    }
    if (css) {
      var styles = css_to_keyframe(css(0, 1));
      keyframes.push(styles, styles);
    }
  }
  var get_t = () => 1 - t2;
  var animation2 = element2.animate(keyframes, { duration: delay, fill: "forwards" });
  animation2.onfinish = () => {
    animation2.cancel();
    var t1 = counterpart?.t() ?? 1 - t2;
    counterpart?.abort();
    var delta = t2 - t1;
    var duration = (
      /** @type {number} */
      options.duration * Math.abs(delta)
    );
    var keyframes2 = [];
    if (duration > 0) {
      var needs_overflow_hidden = false;
      if (css) {
        var n = Math.ceil(duration / (1e3 / 60));
        for (var i = 0; i <= n; i += 1) {
          var t = t1 + delta * easing(i / n);
          var styles2 = css_to_keyframe(css(t, 1 - t));
          keyframes2.push(styles2);
          needs_overflow_hidden ||= styles2.overflow === "hidden";
        }
      }
      if (needs_overflow_hidden) {
        element2.style.overflow = "hidden";
      }
      get_t = () => {
        var time = (
          /** @type {number} */
          /** @type {globalThis.Animation} */
          animation2.currentTime
        );
        return t1 + delta * easing(time / duration);
      };
      if (tick3) {
        loop(() => {
          if (animation2.playState !== "running") return false;
          var t3 = get_t();
          tick3(t3, 1 - t3);
          return true;
        });
      }
    }
    animation2 = element2.animate(keyframes2, { duration, fill: "forwards" });
    animation2.onfinish = () => {
      get_t = () => t2;
      tick3?.(t2, 1 - t2);
      on_finish();
    };
  };
  return {
    abort: () => {
      if (animation2) {
        animation2.cancel();
        animation2.effect = null;
        animation2.onfinish = noop;
      }
    },
    deactivate: () => {
      on_finish = noop;
    },
    reset: () => {
      if (t2 === 0) {
        tick3?.(1, 0);
      }
    },
    t: () => get_t()
  };
}
var linear;
var init_transitions = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/transitions.js"() {
    init_utils();
    init_effects();
    init_runtime();
    init_loop();
    init_render();
    init_each();
    init_constants();
    init_constants2();
    init_task();
    init_shared();
    linear = (t) => t;
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/document.js
function bind_active_element(update2) {
  listen(document, ["focusin", "focusout"], (event2) => {
    if (event2 && event2.type === "focusout" && /** @type {FocusEvent} */
    event2.relatedTarget) {
      return;
    }
    update2(document.activeElement);
  });
}
var init_document = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/document.js"() {
    init_shared();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/input.js
function bind_value(input, get3, set2 = get3) {
  var batches2 = /* @__PURE__ */ new WeakSet();
  listen_to_event_and_reset_event(input, "input", async (is_reset) => {
    if (true_default && input.type === "checkbox") {
      bind_invalid_checkbox_value();
    }
    var value = is_reset ? input.defaultValue : input.value;
    value = is_numberlike_input(input) ? to_number(value) : value;
    set2(value);
    if (current_batch !== null) {
      batches2.add(current_batch);
    }
    await tick();
    if (value !== (value = get3())) {
      var start = input.selectionStart;
      var end = input.selectionEnd;
      var length = input.value.length;
      input.value = value ?? "";
      if (end !== null) {
        var new_length = input.value.length;
        if (start === end && end === length && new_length > length) {
          input.selectionStart = new_length;
          input.selectionEnd = new_length;
        } else {
          input.selectionStart = start;
          input.selectionEnd = Math.min(end, new_length);
        }
      }
    }
  });
  if (
    // If we are hydrating and the value has since changed,
    // then use the updated value from the input instead.
    hydrating && input.defaultValue !== input.value || // If defaultValue is set, then value == defaultValue
    // TODO Svelte 6: remove input.value check and set to empty string?
    untrack(get3) == null && input.value
  ) {
    set2(is_numberlike_input(input) ? to_number(input.value) : input.value);
    if (current_batch !== null) {
      batches2.add(current_batch);
    }
  }
  render_effect(() => {
    if (true_default && input.type === "checkbox") {
      bind_invalid_checkbox_value();
    }
    var value = get3();
    if (input === document.activeElement) {
      var batch = (
        /** @type {Batch} */
        previous_batch ?? current_batch
      );
      if (batches2.has(batch)) {
        return;
      }
    }
    if (is_numberlike_input(input) && value === to_number(input.value)) {
      return;
    }
    if (input.type === "date" && !value && !input.value) {
      return;
    }
    if (value !== input.value) {
      input.value = value ?? "";
    }
  });
}
function bind_group(inputs, group_index, input, get3, set2 = get3) {
  var is_checkbox = input.getAttribute("type") === "checkbox";
  var binding_group = inputs;
  let hydration_mismatch2 = false;
  if (group_index !== null) {
    for (var index2 of group_index) {
      binding_group = binding_group[index2] ??= [];
    }
  }
  binding_group.push(input);
  listen_to_event_and_reset_event(
    input,
    "change",
    () => {
      var value = input.__value;
      if (is_checkbox) {
        value = get_binding_group_value(binding_group, value, input.checked);
      }
      set2(value);
    },
    // TODO better default value handling
    () => set2(is_checkbox ? [] : null)
  );
  render_effect(() => {
    var value = get3();
    if (hydrating && input.defaultChecked !== input.checked) {
      hydration_mismatch2 = true;
      return;
    }
    if (is_checkbox) {
      value = value || [];
      input.checked = value.includes(input.__value);
    } else {
      input.checked = is(input.__value, value);
    }
  });
  teardown(() => {
    var index3 = binding_group.indexOf(input);
    if (index3 !== -1) {
      binding_group.splice(index3, 1);
    }
  });
  if (!pending2.has(binding_group)) {
    pending2.add(binding_group);
    queue_micro_task(() => {
      binding_group.sort((a, b) => a.compareDocumentPosition(b) === 4 ? -1 : 1);
      pending2.delete(binding_group);
    });
  }
  queue_micro_task(() => {
    if (hydration_mismatch2) {
      var value;
      if (is_checkbox) {
        value = get_binding_group_value(binding_group, value, input.checked);
      } else {
        var hydration_input = binding_group.find((input2) => input2.checked);
        value = hydration_input?.__value;
      }
      set2(value);
    }
  });
}
function bind_checked(input, get3, set2 = get3) {
  listen_to_event_and_reset_event(input, "change", (is_reset) => {
    var value = is_reset ? input.defaultChecked : input.checked;
    set2(value);
  });
  if (
    // If we are hydrating and the value has since changed,
    // then use the update value from the input instead.
    hydrating && input.defaultChecked !== input.checked || // If defaultChecked is set, then checked == defaultChecked
    untrack(get3) == null
  ) {
    set2(input.checked);
  }
  render_effect(() => {
    var value = get3();
    input.checked = Boolean(value);
  });
}
function get_binding_group_value(group, __value, checked) {
  var value = /* @__PURE__ */ new Set();
  for (var i = 0; i < group.length; i += 1) {
    if (group[i].checked) {
      value.add(group[i].__value);
    }
  }
  if (!checked) {
    value.delete(__value);
  }
  return Array.from(value);
}
function is_numberlike_input(input) {
  var type = input.type;
  return type === "number" || type === "range";
}
function to_number(value) {
  return value === "" ? null : +value;
}
function bind_files(input, get3, set2 = get3) {
  listen_to_event_and_reset_event(input, "change", () => {
    set2(input.files);
  });
  if (
    // If we are hydrating and the value has since changed,
    // then use the updated value from the input instead.
    hydrating && input.files
  ) {
    set2(input.files);
  }
  render_effect(() => {
    input.files = get3();
  });
}
var pending2;
var init_input = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/input.js"() {
    init_esm_env();
    init_effects();
    init_shared();
    init_errors2();
    init_proxy();
    init_task();
    init_hydration();
    init_runtime();
    init_context();
    init_batch();
    pending2 = /* @__PURE__ */ new Set();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/media.js
function time_ranges_to_array(ranges) {
  var array = [];
  for (var i = 0; i < ranges.length; i += 1) {
    array.push({ start: ranges.start(i), end: ranges.end(i) });
  }
  return array;
}
function bind_current_time(media, get3, set2 = get3) {
  var raf_id;
  var value;
  var callback = () => {
    cancelAnimationFrame(raf_id);
    if (!media.paused) {
      raf_id = requestAnimationFrame(callback);
    }
    var next_value = media.currentTime;
    if (value !== next_value) {
      set2(value = next_value);
    }
  };
  raf_id = requestAnimationFrame(callback);
  media.addEventListener("timeupdate", callback);
  render_effect(() => {
    var next_value = Number(get3());
    if (value !== next_value && !isNaN(
      /** @type {any} */
      next_value
    )) {
      media.currentTime = value = next_value;
    }
  });
  teardown(() => {
    cancelAnimationFrame(raf_id);
    media.removeEventListener("timeupdate", callback);
  });
}
function bind_buffered(media, set2) {
  var current;
  listen(media, ["loadedmetadata", "progress", "timeupdate", "seeking"], () => {
    var ranges = media.buffered;
    if (!current || current.length !== ranges.length || current.some((range, i) => ranges.start(i) !== range.start || ranges.end(i) !== range.end)) {
      current = time_ranges_to_array(ranges);
      set2(current);
    }
  });
}
function bind_seekable(media, set2) {
  listen(media, ["loadedmetadata"], () => set2(time_ranges_to_array(media.seekable)));
}
function bind_played(media, set2) {
  listen(media, ["timeupdate"], () => set2(time_ranges_to_array(media.played)));
}
function bind_seeking(media, set2) {
  listen(media, ["seeking", "seeked"], () => set2(media.seeking));
}
function bind_ended(media, set2) {
  listen(media, ["timeupdate", "ended"], () => set2(media.ended));
}
function bind_ready_state(media, set2) {
  listen(
    media,
    ["loadedmetadata", "loadeddata", "canplay", "canplaythrough", "playing", "waiting", "emptied"],
    () => set2(media.readyState)
  );
}
function bind_playback_rate(media, get3, set2 = get3) {
  effect(() => {
    var value = Number(get3());
    if (value !== media.playbackRate && !isNaN(value)) {
      media.playbackRate = value;
    }
  });
  effect(() => {
    listen(media, ["ratechange"], () => {
      set2(media.playbackRate);
    });
  });
}
function bind_paused(media, get3, set2 = get3) {
  var paused = get3();
  var update2 = () => {
    if (paused !== media.paused) {
      set2(paused = media.paused);
    }
  };
  listen(media, ["play", "pause", "canplay"], update2, paused == null);
  effect(() => {
    if ((paused = !!get3()) !== media.paused) {
      if (paused) {
        media.pause();
      } else {
        media.play().catch(() => {
          set2(paused = true);
        });
      }
    }
  });
}
function bind_volume(media, get3, set2 = get3) {
  var callback = () => {
    set2(media.volume);
  };
  if (get3() == null) {
    callback();
  }
  listen(media, ["volumechange"], callback, false);
  render_effect(() => {
    var value = Number(get3());
    if (value !== media.volume && !isNaN(value)) {
      media.volume = value;
    }
  });
}
function bind_muted(media, get3, set2 = get3) {
  var callback = () => {
    set2(media.muted);
  };
  if (get3() == null) {
    callback();
  }
  listen(media, ["volumechange"], callback, false);
  render_effect(() => {
    var value = !!get3();
    if (media.muted !== value) media.muted = value;
  });
}
var init_media = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/media.js"() {
    init_effects();
    init_shared();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/navigator.js
function bind_online(update2) {
  listen(window, ["online", "offline"], () => {
    update2(navigator.onLine);
  });
}
var init_navigator = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/navigator.js"() {
    init_shared();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/props.js
function bind_prop(props, prop2, value) {
  var desc = get_descriptor(props, prop2);
  if (desc && desc.set) {
    props[prop2] = value;
    teardown(() => {
      props[prop2] = null;
    });
  }
}
var init_props = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/props.js"() {
    init_effects();
    init_utils();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/size.js
function bind_resize_observer(element2, type, set2) {
  var observer = type === "contentRect" || type === "contentBoxSize" ? resize_observer_content_box : type === "borderBoxSize" ? resize_observer_border_box : resize_observer_device_pixel_content_box;
  var unsub = observer.observe(
    element2,
    /** @param {any} entry */
    (entry) => set2(entry[type])
  );
  teardown(unsub);
}
function bind_element_size(element2, type, set2) {
  var unsub = resize_observer_border_box.observe(element2, () => set2(element2[type]));
  effect(() => {
    untrack(() => set2(element2[type]));
    return unsub;
  });
}
var ResizeObserverSingleton, resize_observer_content_box, resize_observer_border_box, resize_observer_device_pixel_content_box;
var init_size = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/size.js"() {
    init_effects();
    init_runtime();
    ResizeObserverSingleton = class _ResizeObserverSingleton {
      /** */
      #listeners = /* @__PURE__ */ new WeakMap();
      /** @type {ResizeObserver | undefined} */
      #observer;
      /** @type {ResizeObserverOptions} */
      #options;
      /** @static */
      static entries = /* @__PURE__ */ new WeakMap();
      /** @param {ResizeObserverOptions} options */
      constructor(options) {
        this.#options = options;
      }
      /**
       * @param {Element} element
       * @param {(entry: ResizeObserverEntry) => any} listener
       */
      observe(element2, listener) {
        var listeners = this.#listeners.get(element2) || /* @__PURE__ */ new Set();
        listeners.add(listener);
        this.#listeners.set(element2, listeners);
        this.#getObserver().observe(element2, this.#options);
        return () => {
          var listeners2 = this.#listeners.get(element2);
          listeners2.delete(listener);
          if (listeners2.size === 0) {
            this.#listeners.delete(element2);
            this.#observer.unobserve(element2);
          }
        };
      }
      #getObserver() {
        return this.#observer ?? (this.#observer = new ResizeObserver(
          /** @param {any} entries */
          (entries) => {
            for (var entry of entries) {
              _ResizeObserverSingleton.entries.set(entry.target, entry);
              for (var listener of this.#listeners.get(entry.target) || []) {
                listener(entry);
              }
            }
          }
        ));
      }
    };
    resize_observer_content_box = /* @__PURE__ */ new ResizeObserverSingleton({
      box: "content-box"
    });
    resize_observer_border_box = /* @__PURE__ */ new ResizeObserverSingleton({
      box: "border-box"
    });
    resize_observer_device_pixel_content_box = /* @__PURE__ */ new ResizeObserverSingleton({
      box: "device-pixel-content-box"
    });
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/this.js
function is_bound_this(bound_value, element_or_component) {
  return bound_value === element_or_component || bound_value?.[STATE_SYMBOL] === element_or_component;
}
function bind_this(element_or_component = {}, update2, get_value, get_parts) {
  effect(() => {
    var old_parts;
    var parts;
    render_effect(() => {
      old_parts = parts;
      parts = get_parts?.() || [];
      untrack(() => {
        if (element_or_component !== get_value(...parts)) {
          update2(element_or_component, ...parts);
          if (old_parts && is_bound_this(get_value(...old_parts), element_or_component)) {
            update2(null, ...old_parts);
          }
        }
      });
    });
    return () => {
      queue_micro_task(() => {
        if (parts && is_bound_this(get_value(...parts), element_or_component)) {
          update2(null, ...parts);
        }
      });
    };
  });
  return element_or_component;
}
var init_this = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/this.js"() {
    init_constants2();
    init_effects();
    init_runtime();
    init_task();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/universal.js
function bind_content_editable(property, element2, get3, set2 = get3) {
  element2.addEventListener("input", () => {
    set2(element2[property]);
  });
  render_effect(() => {
    var value = get3();
    if (element2[property] !== value) {
      if (value == null) {
        var non_null_value = element2[property];
        set2(non_null_value);
      } else {
        element2[property] = value + "";
      }
    }
  });
}
function bind_property(property, event_name, element2, set2, get3) {
  var handler = () => {
    set2(element2[property]);
  };
  element2.addEventListener(event_name, handler);
  if (get3) {
    render_effect(() => {
      element2[property] = get3();
    });
  } else {
    handler();
  }
  if (element2 === document.body || element2 === window || element2 === document) {
    teardown(() => {
      element2.removeEventListener(event_name, handler);
    });
  }
}
function bind_focused(element2, set2) {
  listen(element2, ["focus", "blur"], () => {
    set2(element2 === document.activeElement);
  });
}
var init_universal = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/universal.js"() {
    init_effects();
    init_shared();
  }
});

// node_modules/svelte/src/internal/client/dom/elements/bindings/window.js
function bind_window_scroll(type, get3, set2 = get3) {
  var is_scrolling_x = type === "x";
  var target_handler = () => without_reactive_context(() => {
    scrolling = true;
    clearTimeout(timeout);
    timeout = setTimeout(clear, 100);
    set2(window[is_scrolling_x ? "scrollX" : "scrollY"]);
  });
  addEventListener("scroll", target_handler, {
    passive: true
  });
  var scrolling = false;
  var timeout;
  var clear = () => {
    scrolling = false;
  };
  var first = true;
  render_effect(() => {
    var latest_value = get3();
    if (first) {
      first = false;
    } else if (!scrolling && latest_value != null) {
      scrolling = true;
      clearTimeout(timeout);
      if (is_scrolling_x) {
        scrollTo(latest_value, window.scrollY);
      } else {
        scrollTo(window.scrollX, latest_value);
      }
      timeout = setTimeout(clear, 100);
    }
  });
  effect(target_handler);
  teardown(() => {
    removeEventListener("scroll", target_handler);
  });
}
function bind_window_size(type, set2) {
  listen(window, ["resize"], () => without_reactive_context(() => set2(window[type])));
}
var init_window = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/bindings/window.js"() {
    init_effects();
    init_shared();
  }
});

// node_modules/svelte/src/internal/client/dom/legacy/event-modifiers.js
function trusted(fn) {
  return function(...args) {
    var event2 = (
      /** @type {Event} */
      args[0]
    );
    if (event2.isTrusted) {
      fn?.apply(this, args);
    }
  };
}
function self(fn) {
  return function(...args) {
    var event2 = (
      /** @type {Event} */
      args[0]
    );
    if (event2.target === this) {
      fn?.apply(this, args);
    }
  };
}
function stopPropagation(fn) {
  return function(...args) {
    var event2 = (
      /** @type {Event} */
      args[0]
    );
    event2.stopPropagation();
    return fn?.apply(this, args);
  };
}
function once(fn) {
  var ran = false;
  return function(...args) {
    if (ran) return;
    ran = true;
    return fn?.apply(this, args);
  };
}
function stopImmediatePropagation(fn) {
  return function(...args) {
    var event2 = (
      /** @type {Event} */
      args[0]
    );
    event2.stopImmediatePropagation();
    return fn?.apply(this, args);
  };
}
function preventDefault(fn) {
  return function(...args) {
    var event2 = (
      /** @type {Event} */
      args[0]
    );
    event2.preventDefault();
    return fn?.apply(this, args);
  };
}
var init_event_modifiers = __esm({
  "node_modules/svelte/src/internal/client/dom/legacy/event-modifiers.js"() {
    init_utils();
    init_effects();
    init_events();
  }
});

// node_modules/svelte/src/internal/client/dom/legacy/lifecycle.js
function init(immutable = false) {
  const context2 = (
    /** @type {ComponentContextLegacy} */
    component_context
  );
  const callbacks = context2.l.u;
  if (!callbacks) return;
  let props = () => deep_read_state(context2.s);
  if (immutable) {
    let version = 0;
    let prev = (
      /** @type {Record<string, any>} */
      {}
    );
    const d = derived(() => {
      let changed = false;
      const props2 = context2.s;
      for (const key2 in props2) {
        if (props2[key2] !== prev[key2]) {
          prev[key2] = props2[key2];
          changed = true;
        }
      }
      if (changed) version++;
      return version;
    });
    props = () => get(d);
  }
  if (callbacks.b.length) {
    user_pre_effect(() => {
      observe_all(context2, props);
      run_all(callbacks.b);
    });
  }
  user_effect(() => {
    const fns = untrack(() => callbacks.m.map(run));
    return () => {
      for (const fn of fns) {
        if (typeof fn === "function") {
          fn();
        }
      }
    };
  });
  if (callbacks.a.length) {
    user_effect(() => {
      observe_all(context2, props);
      run_all(callbacks.a);
    });
  }
}
function observe_all(context2, props) {
  if (context2.l.s) {
    for (const signal of context2.l.s) get(signal);
  }
  props();
}
var init_lifecycle = __esm({
  "node_modules/svelte/src/internal/client/dom/legacy/lifecycle.js"() {
    init_utils();
    init_context();
    init_deriveds();
    init_effects();
    init_runtime();
  }
});

// node_modules/svelte/src/internal/client/dom/legacy/misc.js
function reactive_import(fn) {
  var s = source(0);
  return function() {
    if (arguments.length === 1) {
      set(s, get(s) + 1);
      return arguments[0];
    } else {
      get(s);
      return fn();
    }
  };
}
function bubble_event($$props, event2) {
  var events = (
    /** @type {Record<string, Function[] | Function>} */
    $$props.$$events?.[event2.type]
  );
  var callbacks = is_array(events) ? events.slice() : events == null ? [] : [events];
  for (var fn of callbacks) {
    fn.call(this, event2);
  }
}
function add_legacy_event_listener($$props, event_name, event_callback) {
  $$props.$$events ||= {};
  $$props.$$events[event_name] ||= [];
  $$props.$$events[event_name].push(event_callback);
}
function update_legacy_props($$new_props) {
  for (var key2 in $$new_props) {
    if (key2 in this) {
      this[key2] = $$new_props[key2];
    }
  }
}
var init_misc2 = __esm({
  "node_modules/svelte/src/internal/client/dom/legacy/misc.js"() {
    init_sources();
    init_runtime();
    init_utils();
  }
});

// node_modules/svelte/src/store/shared/index.js
function get2(store) {
  let value;
  subscribe_to_store(store, (_) => value = _)();
  return value;
}
var init_shared2 = __esm({
  "node_modules/svelte/src/store/shared/index.js"() {
    init_utils();
    init_equality();
    init_utils3();
  }
});

// node_modules/svelte/src/internal/client/reactivity/store.js
function store_get(store, store_name, stores) {
  const entry = stores[store_name] ??= {
    store: null,
    source: mutable_source(void 0),
    unsubscribe: noop
  };
  if (true_default) {
    entry.source.label = store_name;
  }
  if (entry.store !== store && !(IS_UNMOUNTED in stores)) {
    entry.unsubscribe();
    entry.store = store ?? null;
    if (store == null) {
      entry.source.v = void 0;
      entry.unsubscribe = noop;
    } else {
      var is_synchronous_callback = true;
      entry.unsubscribe = subscribe_to_store(store, (v) => {
        if (is_synchronous_callback) {
          entry.source.v = v;
        } else {
          set(entry.source, v);
        }
      });
      is_synchronous_callback = false;
    }
  }
  if (store && IS_UNMOUNTED in stores) {
    return get2(store);
  }
  return get(entry.source);
}
function store_unsub(store, store_name, stores) {
  let entry = stores[store_name];
  if (entry && entry.store !== store) {
    entry.unsubscribe();
    entry.unsubscribe = noop;
  }
  return store;
}
function store_set(store, value) {
  store.set(value);
  return value;
}
function invalidate_store(stores, store_name) {
  var entry = stores[store_name];
  if (entry.store !== null) {
    store_set(entry.store, entry.source.v);
  }
}
function setup_stores() {
  const stores = {};
  function cleanup() {
    teardown(() => {
      for (var store_name in stores) {
        const ref = stores[store_name];
        ref.unsubscribe();
      }
      define_property(stores, IS_UNMOUNTED, {
        enumerable: false,
        value: true
      });
    });
  }
  return [stores, cleanup];
}
function store_mutate(store, expression, new_value) {
  store.set(new_value);
  return expression;
}
function update_store(store, store_value, d = 1) {
  store.set(store_value + d);
  return store_value;
}
function update_pre_store(store, store_value, d = 1) {
  const value = store_value + d;
  store.set(value);
  return value;
}
function mark_store_binding() {
  is_store_binding = true;
}
function capture_store_binding(fn) {
  var previous_is_store_binding = is_store_binding;
  try {
    is_store_binding = false;
    return [fn(), is_store_binding];
  } finally {
    is_store_binding = previous_is_store_binding;
  }
}
var is_store_binding, IS_UNMOUNTED;
var init_store = __esm({
  "node_modules/svelte/src/internal/client/reactivity/store.js"() {
    init_utils3();
    init_shared2();
    init_utils();
    init_runtime();
    init_effects();
    init_sources();
    init_esm_env();
    is_store_binding = false;
    IS_UNMOUNTED = Symbol();
  }
});

// node_modules/svelte/src/internal/client/reactivity/props.js
function update_prop(fn, d = 1) {
  const value = fn();
  fn(value + d);
  return value;
}
function update_pre_prop(fn, d = 1) {
  const value = fn() + d;
  fn(value);
  return value;
}
// @__NO_SIDE_EFFECTS__
function rest_props(props, exclude, name) {
  return new Proxy(
    true_default ? { props, exclude, name, other: {}, to_proxy: [] } : { props, exclude },
    rest_props_handler
  );
}
function legacy_rest_props(props, exclude) {
  return new Proxy(
    {
      props,
      exclude,
      special: {},
      version: source(0),
      // TODO this is only necessary because we need to track component
      // destruction inside `prop`, because of `bind:this`, but it
      // seems likely that we can simplify `bind:this` instead
      parent_effect: (
        /** @type {Effect} */
        active_effect
      )
    },
    legacy_rest_props_handler
  );
}
function spread_props(...props) {
  return new Proxy({ props }, spread_props_handler);
}
function prop(props, key2, flags2, fallback2) {
  var runes = !legacy_mode_flag || (flags2 & PROPS_IS_RUNES) !== 0;
  var bindable = (flags2 & PROPS_IS_BINDABLE) !== 0;
  var lazy = (flags2 & PROPS_IS_LAZY_INITIAL) !== 0;
  var fallback_value = (
    /** @type {V} */
    fallback2
  );
  var fallback_dirty = true;
  var get_fallback = () => {
    if (fallback_dirty) {
      fallback_dirty = false;
      fallback_value = lazy ? untrack(
        /** @type {() => V} */
        fallback2
      ) : (
        /** @type {V} */
        fallback2
      );
    }
    return fallback_value;
  };
  var setter;
  if (bindable) {
    var is_entry_props = STATE_SYMBOL in props || LEGACY_PROPS in props;
    setter = get_descriptor(props, key2)?.set ?? (is_entry_props && key2 in props ? (v) => props[key2] = v : void 0);
  }
  var initial_value;
  var is_store_sub = false;
  if (bindable) {
    [initial_value, is_store_sub] = capture_store_binding(() => (
      /** @type {V} */
      props[key2]
    ));
  } else {
    initial_value = /** @type {V} */
    props[key2];
  }
  if (initial_value === void 0 && fallback2 !== void 0) {
    initial_value = get_fallback();
    if (setter) {
      if (runes) props_invalid_value(key2);
      setter(initial_value);
    }
  }
  var getter;
  if (runes) {
    getter = () => {
      var value = (
        /** @type {V} */
        props[key2]
      );
      if (value === void 0) return get_fallback();
      fallback_dirty = true;
      return value;
    };
  } else {
    getter = () => {
      var value = (
        /** @type {V} */
        props[key2]
      );
      if (value !== void 0) {
        fallback_value = /** @type {V} */
        void 0;
      }
      return value === void 0 ? fallback_value : value;
    };
  }
  if (runes && (flags2 & PROPS_IS_UPDATED) === 0) {
    return getter;
  }
  if (setter) {
    var legacy_parent = props.$$legacy;
    return (
      /** @type {() => V} */
      (function(value, mutation) {
        if (arguments.length > 0) {
          if (!runes || !mutation || legacy_parent || is_store_sub) {
            setter(mutation ? getter() : value);
          }
          return value;
        }
        return getter();
      })
    );
  }
  var overridden = false;
  var d = ((flags2 & PROPS_IS_IMMUTABLE) !== 0 ? derived : derived_safe_equal)(() => {
    overridden = false;
    return getter();
  });
  if (true_default) {
    d.label = key2;
  }
  if (bindable) get(d);
  var parent_effect = (
    /** @type {Effect} */
    active_effect
  );
  return (
    /** @type {() => V} */
    (function(value, mutation) {
      if (arguments.length > 0) {
        const new_value = mutation ? get(d) : runes && bindable ? proxy(value) : value;
        set(d, new_value);
        overridden = true;
        if (fallback_value !== void 0) {
          fallback_value = new_value;
        }
        return value;
      }
      if (is_destroying_effect && overridden || (parent_effect.f & DESTROYED) !== 0) {
        return d.v;
      }
      return get(d);
    })
  );
}
var rest_props_handler, legacy_rest_props_handler, spread_props_handler;
var init_props2 = __esm({
  "node_modules/svelte/src/internal/client/reactivity/props.js"() {
    init_esm_env();
    init_constants();
    init_utils();
    init_sources();
    init_deriveds();
    init_runtime();
    init_errors2();
    init_constants2();
    init_proxy();
    init_store();
    init_flags();
    rest_props_handler = {
      get(target, key2) {
        if (target.exclude.includes(key2)) return;
        return target.props[key2];
      },
      set(target, key2) {
        if (true_default) {
          props_rest_readonly(`${target.name}.${String(key2)}`);
        }
        return false;
      },
      getOwnPropertyDescriptor(target, key2) {
        if (target.exclude.includes(key2)) return;
        if (key2 in target.props) {
          return {
            enumerable: true,
            configurable: true,
            value: target.props[key2]
          };
        }
      },
      has(target, key2) {
        if (target.exclude.includes(key2)) return false;
        return key2 in target.props;
      },
      ownKeys(target) {
        return Reflect.ownKeys(target.props).filter((key2) => !target.exclude.includes(key2));
      }
    };
    legacy_rest_props_handler = {
      get(target, key2) {
        if (target.exclude.includes(key2)) return;
        get(target.version);
        return key2 in target.special ? target.special[key2]() : target.props[key2];
      },
      set(target, key2, value) {
        if (!(key2 in target.special)) {
          var previous_effect = active_effect;
          try {
            set_active_effect(target.parent_effect);
            target.special[key2] = prop(
              {
                get [key2]() {
                  return target.props[key2];
                }
              },
              /** @type {string} */
              key2,
              PROPS_IS_UPDATED
            );
          } finally {
            set_active_effect(previous_effect);
          }
        }
        target.special[key2](value);
        update(target.version);
        return true;
      },
      getOwnPropertyDescriptor(target, key2) {
        if (target.exclude.includes(key2)) return;
        if (key2 in target.props) {
          return {
            enumerable: true,
            configurable: true,
            value: target.props[key2]
          };
        }
      },
      deleteProperty(target, key2) {
        if (target.exclude.includes(key2)) return true;
        target.exclude.push(key2);
        update(target.version);
        return true;
      },
      has(target, key2) {
        if (target.exclude.includes(key2)) return false;
        return key2 in target.props;
      },
      ownKeys(target) {
        return Reflect.ownKeys(target.props).filter((key2) => !target.exclude.includes(key2));
      }
    };
    spread_props_handler = {
      get(target, key2) {
        let i = target.props.length;
        while (i--) {
          let p = target.props[i];
          if (is_function(p)) p = p();
          if (typeof p === "object" && p !== null && key2 in p) return p[key2];
        }
      },
      set(target, key2, value) {
        let i = target.props.length;
        while (i--) {
          let p = target.props[i];
          if (is_function(p)) p = p();
          const desc = get_descriptor(p, key2);
          if (desc && desc.set) {
            desc.set(value);
            return true;
          }
        }
        return false;
      },
      getOwnPropertyDescriptor(target, key2) {
        let i = target.props.length;
        while (i--) {
          let p = target.props[i];
          if (is_function(p)) p = p();
          if (typeof p === "object" && p !== null && key2 in p) {
            const descriptor = get_descriptor(p, key2);
            if (descriptor && !descriptor.configurable) {
              descriptor.configurable = true;
            }
            return descriptor;
          }
        }
      },
      has(target, key2) {
        if (key2 === STATE_SYMBOL || key2 === LEGACY_PROPS) return false;
        for (let p of target.props) {
          if (is_function(p)) p = p();
          if (p != null && key2 in p) return true;
        }
        return false;
      },
      ownKeys(target) {
        const keys = [];
        for (let p of target.props) {
          if (is_function(p)) p = p();
          if (!p) continue;
          for (const key2 in p) {
            if (!keys.includes(key2)) keys.push(key2);
          }
          for (const key2 of Object.getOwnPropertySymbols(p)) {
            if (!keys.includes(key2)) keys.push(key2);
          }
        }
        return keys;
      }
    };
  }
});

// node_modules/svelte/src/internal/client/validate.js
function validate_each_keys(collection, key_fn) {
  render_effect(() => {
    const keys = /* @__PURE__ */ new Map();
    const maybe_array = collection();
    const array = is_array(maybe_array) ? maybe_array : maybe_array == null ? [] : Array.from(maybe_array);
    const length = array.length;
    for (let i = 0; i < length; i++) {
      const key2 = key_fn(array[i], i);
      if (keys.has(key2)) {
        const a = String(keys.get(key2));
        const b = String(i);
        let k = String(key2);
        if (k.startsWith("[object ")) k = null;
        each_key_duplicate(a, b, k);
      }
      keys.set(key2, i);
    }
  });
}
function validate_binding(binding, blockers, get_object, get_property, line, column) {
  run_after_blockers(blockers, () => {
    var warned = false;
    var filename = dev_current_component_function?.[FILENAME];
    render_effect(() => {
      if (warned) return;
      var [object, is_store_sub] = capture_store_binding(get_object);
      if (is_store_sub) return;
      var property = get_property();
      var ran = false;
      var effect2 = render_effect(() => {
        if (ran) return;
        object[property];
      });
      ran = true;
      if (effect2.deps === null) {
        var location = `${filename}:${line}:${column}`;
        binding_property_non_reactive(binding, location);
        warned = true;
      }
    });
  });
}
var init_validate2 = __esm({
  "node_modules/svelte/src/internal/client/validate.js"() {
    init_context();
    init_utils();
    init_errors2();
    init_constants();
    init_effects();
    init_warnings();
    init_store();
    init_async();
  }
});

// node_modules/svelte/src/legacy/legacy-client.js
function createClassComponent(options) {
  return new Svelte4Component(options);
}
var Svelte4Component;
var init_legacy_client = __esm({
  "node_modules/svelte/src/legacy/legacy-client.js"() {
    init_constants2();
    init_effects();
    init_sources();
    init_render();
    init_runtime();
    init_batch();
    init_utils();
    init_errors2();
    init_warnings();
    init_esm_env();
    init_constants();
    init_context();
    init_flags();
    init_event_modifiers();
    Svelte4Component = class {
      /** @type {any} */
      #events;
      /** @type {Record<string, any>} */
      #instance;
      /**
       * @param {ComponentConstructorOptions & {
       *  component: any;
       * }} options
       */
      constructor(options) {
        var sources = /* @__PURE__ */ new Map();
        var add_source = (key2, value) => {
          var s = mutable_source(value, false, false);
          sources.set(key2, s);
          return s;
        };
        const props = new Proxy(
          { ...options.props || {}, $$events: {} },
          {
            get(target, prop2) {
              return get(sources.get(prop2) ?? add_source(prop2, Reflect.get(target, prop2)));
            },
            has(target, prop2) {
              if (prop2 === LEGACY_PROPS) return true;
              get(sources.get(prop2) ?? add_source(prop2, Reflect.get(target, prop2)));
              return Reflect.has(target, prop2);
            },
            set(target, prop2, value) {
              set(sources.get(prop2) ?? add_source(prop2, value), value);
              return Reflect.set(target, prop2, value);
            }
          }
        );
        this.#instance = (options.hydrate ? hydrate : mount)(options.component, {
          target: options.target,
          anchor: options.anchor,
          props,
          context: options.context,
          intro: options.intro ?? false,
          recover: options.recover
        });
        if (!async_mode_flag && (!options?.props?.$$host || options.sync === false)) {
          flushSync();
        }
        this.#events = props.$$events;
        for (const key2 of Object.keys(this.#instance)) {
          if (key2 === "$set" || key2 === "$destroy" || key2 === "$on") continue;
          define_property(this, key2, {
            get() {
              return this.#instance[key2];
            },
            /** @param {any} value */
            set(value) {
              this.#instance[key2] = value;
            },
            enumerable: true
          });
        }
        this.#instance.$set = /** @param {Record<string, any>} next */
        (next2) => {
          Object.assign(props, next2);
        };
        this.#instance.$destroy = () => {
          unmount(this.#instance);
        };
      }
      /** @param {Record<string, any>} props */
      $set(props) {
        this.#instance.$set(props);
      }
      /**
       * @param {string} event
       * @param {(...args: any[]) => any} callback
       * @returns {any}
       */
      $on(event2, callback) {
        this.#events[event2] = this.#events[event2] || [];
        const cb = (...args) => callback.call(this, ...args);
        this.#events[event2].push(cb);
        return () => {
          this.#events[event2] = this.#events[event2].filter(
            /** @param {any} fn */
            (fn) => fn !== cb
          );
        };
      }
      $destroy() {
        this.#instance.$destroy();
      }
    };
  }
});

// node_modules/svelte/src/internal/client/dom/elements/custom-element.js
function get_custom_element_value(prop2, value, props_definition, transform) {
  const type = props_definition[prop2]?.type;
  value = type === "Boolean" && typeof value !== "boolean" ? value != null : value;
  if (!transform || !props_definition[prop2]) {
    return value;
  } else if (transform === "toAttribute") {
    switch (type) {
      case "Object":
      case "Array":
        return value == null ? null : JSON.stringify(value);
      case "Boolean":
        return value ? "" : null;
      case "Number":
        return value == null ? null : value;
      default:
        return value;
    }
  } else {
    switch (type) {
      case "Object":
      case "Array":
        return value && JSON.parse(value);
      case "Boolean":
        return value;
      // conversion already handled above
      case "Number":
        return value != null ? +value : value;
      default:
        return value;
    }
  }
}
function get_custom_elements_slots(element2) {
  const result = {};
  element2.childNodes.forEach((node) => {
    result[
      /** @type {Element} node */
      node.slot || "default"
    ] = true;
  });
  return result;
}
function create_custom_element(Component, props_definition, slots, exports2, use_shadow_dom, extend) {
  let Class = class extends SvelteElement {
    constructor() {
      super(Component, slots, use_shadow_dom);
      this.$$p_d = props_definition;
    }
    static get observedAttributes() {
      return object_keys(props_definition).map(
        (key2) => (props_definition[key2].attribute || key2).toLowerCase()
      );
    }
  };
  object_keys(props_definition).forEach((prop2) => {
    define_property(Class.prototype, prop2, {
      get() {
        return this.$$c && prop2 in this.$$c ? this.$$c[prop2] : this.$$d[prop2];
      },
      set(value) {
        value = get_custom_element_value(prop2, value, props_definition);
        this.$$d[prop2] = value;
        var component2 = this.$$c;
        if (component2) {
          var setter = get_descriptor(component2, prop2)?.get;
          if (setter) {
            component2[prop2] = value;
          } else {
            component2.$set({ [prop2]: value });
          }
        }
      }
    });
  });
  exports2.forEach((property) => {
    define_property(Class.prototype, property, {
      get() {
        return this.$$c?.[property];
      }
    });
  });
  if (extend) {
    Class = extend(Class);
  }
  Component.element = /** @type {any} */
  Class;
  return Class;
}
var SvelteElement;
var init_custom_element = __esm({
  "node_modules/svelte/src/internal/client/dom/elements/custom-element.js"() {
    init_legacy_client();
    init_effects();
    init_template();
    init_utils();
    if (typeof HTMLElement === "function") {
      SvelteElement = class extends HTMLElement {
        /** The Svelte component constructor */
        $$ctor;
        /** Slots */
        $$s;
        /** @type {any} The Svelte component instance */
        $$c;
        /** Whether or not the custom element is connected */
        $$cn = false;
        /** @type {Record<string, any>} Component props data */
        $$d = {};
        /** `true` if currently in the process of reflecting component props back to attributes */
        $$r = false;
        /** @type {Record<string, CustomElementPropDefinition>} Props definition (name, reflected, type etc) */
        $$p_d = {};
        /** @type {Record<string, EventListenerOrEventListenerObject[]>} Event listeners */
        $$l = {};
        /** @type {Map<EventListenerOrEventListenerObject, Function>} Event listener unsubscribe functions */
        $$l_u = /* @__PURE__ */ new Map();
        /** @type {any} The managed render effect for reflecting attributes */
        $$me;
        /**
         * @param {*} $$componentCtor
         * @param {*} $$slots
         * @param {*} use_shadow_dom
         */
        constructor($$componentCtor, $$slots, use_shadow_dom) {
          super();
          this.$$ctor = $$componentCtor;
          this.$$s = $$slots;
          if (use_shadow_dom) {
            this.attachShadow({ mode: "open" });
          }
        }
        /**
         * @param {string} type
         * @param {EventListenerOrEventListenerObject} listener
         * @param {boolean | AddEventListenerOptions} [options]
         */
        addEventListener(type, listener, options) {
          this.$$l[type] = this.$$l[type] || [];
          this.$$l[type].push(listener);
          if (this.$$c) {
            const unsub = this.$$c.$on(type, listener);
            this.$$l_u.set(listener, unsub);
          }
          super.addEventListener(type, listener, options);
        }
        /**
         * @param {string} type
         * @param {EventListenerOrEventListenerObject} listener
         * @param {boolean | AddEventListenerOptions} [options]
         */
        removeEventListener(type, listener, options) {
          super.removeEventListener(type, listener, options);
          if (this.$$c) {
            const unsub = this.$$l_u.get(listener);
            if (unsub) {
              unsub();
              this.$$l_u.delete(listener);
            }
          }
        }
        async connectedCallback() {
          this.$$cn = true;
          if (!this.$$c) {
            let create_slot = function(name) {
              return (anchor) => {
                const slot2 = document.createElement("slot");
                if (name !== "default") slot2.name = name;
                append(anchor, slot2);
              };
            };
            await Promise.resolve();
            if (!this.$$cn || this.$$c) {
              return;
            }
            const $$slots = {};
            const existing_slots = get_custom_elements_slots(this);
            for (const name of this.$$s) {
              if (name in existing_slots) {
                if (name === "default" && !this.$$d.children) {
                  this.$$d.children = create_slot(name);
                  $$slots.default = true;
                } else {
                  $$slots[name] = create_slot(name);
                }
              }
            }
            for (const attribute of this.attributes) {
              const name = this.$$g_p(attribute.name);
              if (!(name in this.$$d)) {
                this.$$d[name] = get_custom_element_value(name, attribute.value, this.$$p_d, "toProp");
              }
            }
            for (const key2 in this.$$p_d) {
              if (!(key2 in this.$$d) && this[key2] !== void 0) {
                this.$$d[key2] = this[key2];
                delete this[key2];
              }
            }
            this.$$c = createClassComponent({
              component: this.$$ctor,
              target: this.shadowRoot || this,
              props: {
                ...this.$$d,
                $$slots,
                $$host: this
              }
            });
            this.$$me = effect_root(() => {
              render_effect(() => {
                this.$$r = true;
                for (const key2 of object_keys(this.$$c)) {
                  if (!this.$$p_d[key2]?.reflect) continue;
                  this.$$d[key2] = this.$$c[key2];
                  const attribute_value = get_custom_element_value(
                    key2,
                    this.$$d[key2],
                    this.$$p_d,
                    "toAttribute"
                  );
                  if (attribute_value == null) {
                    this.removeAttribute(this.$$p_d[key2].attribute || key2);
                  } else {
                    this.setAttribute(this.$$p_d[key2].attribute || key2, attribute_value);
                  }
                }
                this.$$r = false;
              });
            });
            for (const type in this.$$l) {
              for (const listener of this.$$l[type]) {
                const unsub = this.$$c.$on(type, listener);
                this.$$l_u.set(listener, unsub);
              }
            }
            this.$$l = {};
          }
        }
        // We don't need this when working within Svelte code, but for compatibility of people using this outside of Svelte
        // and setting attributes through setAttribute etc, this is helpful
        /**
         * @param {string} attr
         * @param {string} _oldValue
         * @param {string} newValue
         */
        attributeChangedCallback(attr2, _oldValue, newValue) {
          if (this.$$r) return;
          attr2 = this.$$g_p(attr2);
          this.$$d[attr2] = get_custom_element_value(attr2, newValue, this.$$p_d, "toProp");
          this.$$c?.$set({ [attr2]: this.$$d[attr2] });
        }
        disconnectedCallback() {
          this.$$cn = false;
          Promise.resolve().then(() => {
            if (!this.$$cn && this.$$c) {
              this.$$c.$destroy();
              this.$$me();
              this.$$c = void 0;
            }
          });
        }
        /**
         * @param {string} attribute_name
         */
        $$g_p(attribute_name) {
          return object_keys(this.$$p_d).find(
            (key2) => this.$$p_d[key2].attribute === attribute_name || !this.$$p_d[key2].attribute && key2.toLowerCase() === attribute_name
          ) || attribute_name;
        }
      };
    }
  }
});

// node_modules/svelte/src/internal/client/dev/console-log.js
function log_if_contains_state(method, ...objects) {
  untrack(() => {
    try {
      let has_state = false;
      const transformed = [];
      for (const obj of objects) {
        if (obj && typeof obj === "object" && STATE_SYMBOL in obj) {
          transformed.push(snapshot(obj, true));
          has_state = true;
        } else {
          transformed.push(obj);
        }
      }
      if (has_state) {
        console_log_state(method);
        console.log("%c[snapshot]", "color: grey", ...transformed);
      }
    } catch {
    }
  });
  return objects;
}
var init_console_log = __esm({
  "node_modules/svelte/src/internal/client/dev/console-log.js"() {
    init_constants2();
    init_clone();
    init_warnings();
    init_runtime();
  }
});

// node_modules/svelte/src/internal/client/index.js
var client_exports = {};
__export(client_exports, {
  CLASS: () => CLASS,
  FILENAME: () => FILENAME,
  HMR: () => HMR,
  NAMESPACE_SVG: () => NAMESPACE_SVG,
  STYLE: () => STYLE,
  aborted: () => aborted,
  action: () => action,
  active_effect: () => active_effect,
  add_legacy_event_listener: () => add_legacy_event_listener,
  add_locations: () => add_locations,
  add_svelte_meta: () => add_svelte_meta,
  animation: () => animation,
  append: () => append,
  append_styles: () => append_styles2,
  apply: () => apply,
  assign: () => assign,
  assign_and: () => assign_and,
  assign_nullish: () => assign_nullish,
  assign_or: () => assign_or,
  async: () => async,
  async_body: () => async_body,
  async_derived: () => async_derived,
  attach: () => attach,
  attachment: () => createAttachmentKey,
  attr: () => attr,
  attribute_effect: () => attribute_effect,
  autofocus: () => autofocus,
  await: () => await_block,
  bind_active_element: () => bind_active_element,
  bind_buffered: () => bind_buffered,
  bind_checked: () => bind_checked,
  bind_content_editable: () => bind_content_editable,
  bind_current_time: () => bind_current_time,
  bind_element_size: () => bind_element_size,
  bind_ended: () => bind_ended,
  bind_files: () => bind_files,
  bind_focused: () => bind_focused,
  bind_group: () => bind_group,
  bind_muted: () => bind_muted,
  bind_online: () => bind_online,
  bind_paused: () => bind_paused,
  bind_playback_rate: () => bind_playback_rate,
  bind_played: () => bind_played,
  bind_prop: () => bind_prop,
  bind_property: () => bind_property,
  bind_ready_state: () => bind_ready_state,
  bind_resize_observer: () => bind_resize_observer,
  bind_seekable: () => bind_seekable,
  bind_seeking: () => bind_seeking,
  bind_select_value: () => bind_select_value,
  bind_this: () => bind_this,
  bind_value: () => bind_value,
  bind_volume: () => bind_volume,
  bind_window_scroll: () => bind_window_scroll,
  bind_window_size: () => bind_window_size,
  boundary: () => boundary,
  bubble_event: () => bubble_event,
  check_target: () => check_target,
  child: () => child,
  cleanup_styles: () => cleanup_styles,
  clsx: () => clsx2,
  comment: () => comment,
  component: () => component,
  create_custom_element: () => create_custom_element,
  create_ownership_validator: () => create_ownership_validator,
  css_props: () => css_props,
  deep_read: () => deep_read,
  deep_read_state: () => deep_read_state,
  deferred_template_effect: () => deferred_template_effect,
  delegate: () => delegate,
  derived: () => user_derived,
  derived_safe_equal: () => derived_safe_equal,
  document: () => $document,
  each: () => each,
  eager: () => eager,
  effect: () => effect,
  effect_root: () => effect_root,
  effect_tracking: () => effect_tracking,
  element: () => element,
  equals: () => equals2,
  event: () => event,
  exclude_from_object: () => exclude_from_object,
  fallback: () => fallback,
  first_child: () => first_child,
  flush: () => flushSync,
  for_await_track_reactivity_loss: () => for_await_track_reactivity_loss,
  from_html: () => from_html,
  from_mathml: () => from_mathml,
  from_svg: () => from_svg,
  from_tree: () => from_tree,
  get: () => get,
  head: () => head,
  hmr: () => hmr,
  html: () => html,
  hydrate_template: () => hydrate_template,
  if: () => if_block,
  index: () => index,
  init: () => init,
  init_select: () => init_select2,
  inspect: () => inspect,
  invalid_default_snippet: () => invalid_default_snippet,
  invalidate_inner_signals: () => invalidate_inner_signals,
  invalidate_store: () => invalidate_store,
  invoke_error_boundary: () => invoke_error_boundary,
  key: () => key,
  legacy_api: () => legacy_api,
  legacy_pre_effect: () => legacy_pre_effect,
  legacy_pre_effect_reset: () => legacy_pre_effect_reset,
  legacy_rest_props: () => legacy_rest_props,
  log_if_contains_state: () => log_if_contains_state,
  mark_store_binding: () => mark_store_binding,
  mutable_source: () => mutable_source,
  mutate: () => mutate,
  next: () => next,
  noop: () => noop,
  once: () => once,
  pending: () => pending,
  pop: () => pop,
  preventDefault: () => preventDefault,
  prevent_snippet_stringification: () => prevent_snippet_stringification,
  prop: () => prop,
  props_id: () => props_id,
  proxy: () => proxy,
  push: () => push,
  raf: () => raf,
  reactive_import: () => reactive_import,
  remove_input_defaults: () => remove_input_defaults,
  remove_textarea_child: () => remove_textarea_child,
  render_effect: () => render_effect,
  replay_events: () => replay_events,
  reset: () => reset,
  rest_props: () => rest_props,
  run: () => run2,
  run_after_blockers: () => run_after_blockers,
  safe_get: () => safe_get,
  sanitize_slots: () => sanitize_slots,
  save: () => save,
  select_option: () => select_option,
  self: () => self,
  set: () => set,
  set_attribute: () => set_attribute2,
  set_checked: () => set_checked,
  set_class: () => set_class,
  set_custom_element_data: () => set_custom_element_data,
  set_default_checked: () => set_default_checked,
  set_default_value: () => set_default_value,
  set_selected: () => set_selected,
  set_style: () => set_style,
  set_text: () => set_text,
  set_value: () => set_value,
  set_xlink_attribute: () => set_xlink_attribute,
  setup_stores: () => setup_stores,
  sibling: () => sibling,
  slot: () => slot,
  snapshot: () => snapshot,
  snippet: () => snippet,
  spread_props: () => spread_props,
  state: () => state,
  stopImmediatePropagation: () => stopImmediatePropagation,
  stopPropagation: () => stopPropagation,
  store_get: () => store_get,
  store_mutate: () => store_mutate,
  store_set: () => store_set,
  store_unsub: () => store_unsub,
  strict_equals: () => strict_equals,
  tag: () => tag,
  tag_proxy: () => tag_proxy,
  template_effect: () => template_effect,
  text: () => text,
  tick: () => tick,
  to_array: () => to_array,
  trace: () => trace,
  track_reactivity_loss: () => track_reactivity_loss,
  transition: () => transition,
  trusted: () => trusted,
  untrack: () => untrack,
  update: () => update,
  update_legacy_props: () => update_legacy_props,
  update_pre: () => update_pre,
  update_pre_prop: () => update_pre_prop,
  update_pre_store: () => update_pre_store,
  update_prop: () => update_prop,
  update_store: () => update_store,
  user_effect: () => user_effect,
  user_pre_effect: () => user_pre_effect,
  validate_binding: () => validate_binding,
  validate_dynamic_element_tag: () => validate_dynamic_element_tag,
  validate_each_keys: () => validate_each_keys,
  validate_snippet_args: () => validate_snippet_args,
  validate_store: () => validate_store,
  validate_void_dynamic_element: () => validate_void_dynamic_element,
  window: () => $window,
  with_script: () => with_script,
  wrap_snippet: () => wrap_snippet
});
var init_client = __esm({
  "node_modules/svelte/src/internal/client/index.js"() {
    init_attachments();
    init_constants();
    init_context();
    init_assign();
    init_css();
    init_elements();
    init_hmr();
    init_ownership();
    init_legacy2();
    init_tracing();
    init_inspect();
    init_async2();
    init_validation();
    init_await();
    init_if();
    init_key();
    init_css_props();
    init_each();
    init_html();
    init_slot();
    init_snippet();
    init_svelte_component();
    init_svelte_element();
    init_svelte_head();
    init_css2();
    init_actions();
    init_attachments2();
    init_attributes2();
    init_class();
    init_events();
    init_misc();
    init_style();
    init_transitions();
    init_document();
    init_input();
    init_media();
    init_navigator();
    init_props();
    init_select();
    init_size();
    init_this();
    init_universal();
    init_window();
    init_hydration();
    init_event_modifiers();
    init_lifecycle();
    init_misc2();
    init_template();
    init_async();
    init_batch();
    init_deriveds();
    init_effects();
    init_sources();
    init_props2();
    init_store();
    init_boundary();
    init_legacy();
    init_render();
    init_runtime();
    init_validate2();
    init_timing();
    init_proxy();
    init_custom_element();
    init_operations();
    init_attributes();
    init_clone();
    init_utils();
    init_validate();
    init_equality2();
    init_console_log();
    init_error_handling();
  }
});

// node_modules/svelte/src/internal/client/hydratable.js
var init_hydratable = __esm({
  "node_modules/svelte/src/internal/client/hydratable.js"() {
    init_flags();
    init_hydration();
    init_warnings();
    init_errors2();
    init_esm_env();
  }
});

// node_modules/svelte/src/index-client.js
var init_index_client = __esm({
  "node_modules/svelte/src/index-client.js"() {
    init_runtime();
    init_utils();
    init_client();
    init_errors2();
    init_flags();
    init_context();
    init_esm_env();
    init_batch();
    init_context();
    init_hydratable();
    init_render();
    init_runtime();
    init_snippet();
    if (true_default) {
      let throw_rune_error = function(rune) {
        if (!(rune in globalThis)) {
          let value;
          Object.defineProperty(globalThis, rune, {
            configurable: true,
            // eslint-disable-next-line getter-return
            get: () => {
              if (value !== void 0) {
                return value;
              }
              rune_outside_svelte(rune);
            },
            set: (v) => {
              value = v;
            }
          });
        }
      };
      throw_rune_error("$state");
      throw_rune_error("$effect");
      throw_rune_error("$derived");
      throw_rune_error("$inspect");
      throw_rune_error("$props");
      throw_rune_error("$bindable");
    }
  }
});

// node_modules/svelte/src/store/utils.js
function subscribe_to_store(store, run3, invalidate) {
  if (store == null) {
    run3(void 0);
    if (invalidate) invalidate(void 0);
    return noop;
  }
  const unsub = untrack(
    () => store.subscribe(
      run3,
      // @ts-expect-error
      invalidate
    )
  );
  return unsub.unsubscribe ? () => unsub.unsubscribe() : unsub;
}
var init_utils3 = __esm({
  "node_modules/svelte/src/store/utils.js"() {
    init_index_client();
    init_utils();
  }
});

// node_modules/svelte/src/internal/server/hydration.js
var BLOCK_OPEN, BLOCK_OPEN_ELSE, BLOCK_CLOSE;
var init_hydration2 = __esm({
  "node_modules/svelte/src/internal/server/hydration.js"() {
    init_constants();
    BLOCK_OPEN = `<!--${HYDRATION_START}-->`;
    BLOCK_OPEN_ELSE = `<!--${HYDRATION_START_ELSE}-->`;
    BLOCK_CLOSE = `<!--${HYDRATION_END}-->`;
  }
});

// node_modules/svelte/src/internal/server/abort-signal.js
function abort() {
  controller?.abort(STALE_REACTION);
  controller = null;
}
function getAbortSignal() {
  return (controller ??= new AbortController()).signal;
}
var controller;
var init_abort_signal = __esm({
  "node_modules/svelte/src/internal/server/abort-signal.js"() {
    init_constants2();
    controller = null;
  }
});

// node_modules/svelte/src/internal/server/errors.js
function async_local_storage_unavailable() {
  const error = new Error(`async_local_storage_unavailable
The node API \`AsyncLocalStorage\` is not available, but is required to use async server rendering.
https://svelte.dev/e/async_local_storage_unavailable`);
  error.name = "Svelte error";
  throw error;
}
function await_invalid() {
  const error = new Error(`await_invalid
Encountered asynchronous work while rendering synchronously.
https://svelte.dev/e/await_invalid`);
  error.name = "Svelte error";
  throw error;
}
function html_deprecated() {
  const error = new Error(`html_deprecated
The \`html\` property of server render results has been deprecated. Use \`body\` instead.
https://svelte.dev/e/html_deprecated`);
  error.name = "Svelte error";
  throw error;
}
function hydratable_clobbering(key2, stack2) {
  const error = new Error(`hydratable_clobbering
Attempted to set \`hydratable\` with key \`${key2}\` twice with different values.

${stack2}
https://svelte.dev/e/hydratable_clobbering`);
  error.name = "Svelte error";
  throw error;
}
function hydratable_serialization_failed(key2, stack2) {
  const error = new Error(`hydratable_serialization_failed
Failed to serialize \`hydratable\` data for key \`${key2}\`.

\`hydratable\` can serialize anything [\`uneval\` from \`devalue\`](https://npmjs.com/package/uneval) can, plus Promises.

Cause:
${stack2}
https://svelte.dev/e/hydratable_serialization_failed`);
  error.name = "Svelte error";
  throw error;
}
function lifecycle_function_unavailable(name) {
  const error = new Error(`lifecycle_function_unavailable
\`${name}(...)\` is not available on the server
https://svelte.dev/e/lifecycle_function_unavailable`);
  error.name = "Svelte error";
  throw error;
}
function server_context_required() {
  const error = new Error(`server_context_required
Could not resolve \`render\` context.
https://svelte.dev/e/server_context_required`);
  error.name = "Svelte error";
  throw error;
}
var init_errors3 = __esm({
  "node_modules/svelte/src/internal/server/errors.js"() {
    init_errors();
  }
});

// node_modules/svelte/src/internal/server/context.js
function set_ssr_context(v) {
  ssr_context = v;
}
function createContext2() {
  const key2 = {};
  return [() => getContext2(key2), (context2) => setContext2(key2, context2)];
}
function getContext2(key2) {
  const context_map = get_or_init_context_map("getContext");
  const result = (
    /** @type {T} */
    context_map.get(key2)
  );
  return result;
}
function setContext2(key2, context2) {
  get_or_init_context_map("setContext").set(key2, context2);
  return context2;
}
function hasContext2(key2) {
  return get_or_init_context_map("hasContext").has(key2);
}
function getAllContexts2() {
  return get_or_init_context_map("getAllContexts");
}
function get_or_init_context_map(name) {
  if (ssr_context === null) {
    lifecycle_outside_component(name);
  }
  return ssr_context.c ??= new Map(get_parent_context(ssr_context) || void 0);
}
function push2(fn) {
  ssr_context = { p: ssr_context, c: null, r: null };
  if (true_default) {
    ssr_context.function = fn;
    ssr_context.element = ssr_context.p?.element;
  }
}
function pop2() {
  ssr_context = /** @type {SSRContext} */
  ssr_context.p;
}
function get_parent_context(ssr_context2) {
  let parent = ssr_context2.p;
  while (parent !== null) {
    const context_map = parent.c;
    if (context_map !== null) {
      return context_map;
    }
    parent = parent.p;
  }
  return null;
}
var ssr_context;
var init_context2 = __esm({
  "node_modules/svelte/src/internal/server/context.js"() {
    init_esm_env();
    init_errors3();
    ssr_context = null;
  }
});

// node_modules/svelte/src/internal/server/warnings.js
function unresolved_hydratable(key2, stack2) {
  if (true_default) {
    console.warn(
      `%c[svelte] unresolved_hydratable
%cA \`hydratable\` value with key \`${key2}\` was created, but at least part of it was not used during the render.

The \`hydratable\` was initialized in:
${stack2}
https://svelte.dev/e/unresolved_hydratable`,
      bold3,
      normal3
    );
  } else {
    console.warn(`https://svelte.dev/e/unresolved_hydratable`);
  }
}
var bold3, normal3;
var init_warnings3 = __esm({
  "node_modules/svelte/src/internal/server/warnings.js"() {
    init_esm_env();
    bold3 = "font-weight: bold";
    normal3 = "font-weight: normal";
  }
});

// node_modules/svelte/src/internal/server/render-context.js
function get_render_context() {
  const store = context ?? als?.getStore();
  if (!store) {
    server_context_required();
  }
  return store;
}
async function with_render_context(fn) {
  context = {
    hydratable: {
      lookup: /* @__PURE__ */ new Map(),
      comparisons: [],
      unresolved_promises: /* @__PURE__ */ new Map()
    }
  };
  if (in_webcontainer()) {
    const { promise, resolve } = deferred();
    const previous_render = current_render;
    current_render = promise;
    await previous_render;
    return fn().finally(resolve);
  }
  try {
    if (als === null) {
      async_local_storage_unavailable();
    }
    return als.run(context, fn);
  } finally {
    context = null;
  }
}
async function init_render_context2() {
  if (als !== null) return;
  try {
    const { AsyncLocalStorage } = await import("node:async_hooks");
    als = new AsyncLocalStorage();
  } catch {
  }
}
function in_webcontainer() {
  return !!globalThis.process?.versions?.webcontainer;
}
var current_render, context, als;
var init_render_context = __esm({
  "node_modules/svelte/src/internal/server/render-context.js"() {
    init_utils();
    init_errors3();
    current_render = null;
    context = null;
    als = null;
  }
});

// node_modules/svelte/src/internal/server/renderer.js
var Renderer, SSRState;
var init_renderer = __esm({
  "node_modules/svelte/src/internal/server/renderer.js"() {
    init_flags();
    init_abort_signal();
    init_context2();
    init_errors3();
    init_warnings3();
    init_hydration2();
    init_server();
    init_render_context();
    init_esm_env();
    Renderer = class _Renderer {
      /**
       * The contents of the renderer.
       * @type {RendererItem[]}
       */
      #out = [];
      /**
       * Any `onDestroy` callbacks registered during execution of this renderer.
       * @type {(() => void)[] | undefined}
       */
      #on_destroy = void 0;
      /**
       * Whether this renderer is a component body.
       * @type {boolean}
       */
      #is_component_body = false;
      /**
       * The type of string content that this renderer is accumulating.
       * @type {RendererType}
       */
      type;
      /** @type {Renderer | undefined} */
      #parent;
      /**
       * Asynchronous work associated with this renderer
       * @type {Promise<void> | undefined}
       */
      promise = void 0;
      /**
       * State which is associated with the content tree as a whole.
       * It will be re-exposed, uncopied, on all children.
       * @type {SSRState}
       * @readonly
       */
      global;
      /**
       * State that is local to the branch it is declared in.
       * It will be shallow-copied to all children.
       *
       * @type {{ select_value: string | undefined }}
       */
      local;
      /**
       * @param {SSRState} global
       * @param {Renderer | undefined} [parent]
       */
      constructor(global, parent) {
        this.#parent = parent;
        this.global = global;
        this.local = parent ? { ...parent.local } : { select_value: void 0 };
        this.type = parent ? parent.type : "body";
      }
      /**
       * @param {(renderer: Renderer) => void} fn
       */
      head(fn) {
        const head2 = new _Renderer(this.global, this);
        head2.type = "head";
        this.#out.push(head2);
        head2.child(fn);
      }
      /**
       * @param {Array<Promise<void>>} blockers
       * @param {(renderer: Renderer) => void} fn
       */
      async_block(blockers, fn) {
        this.#out.push(BLOCK_OPEN);
        this.async(blockers, fn);
        this.#out.push(BLOCK_CLOSE);
      }
      /**
       * @param {Array<Promise<void>>} blockers
       * @param {(renderer: Renderer) => void} fn
       */
      async(blockers, fn) {
        let callback = fn;
        if (blockers.length > 0) {
          const context2 = ssr_context;
          callback = (renderer) => {
            return Promise.all(blockers).then(() => {
              const previous_context = ssr_context;
              try {
                set_ssr_context(context2);
                return fn(renderer);
              } finally {
                set_ssr_context(previous_context);
              }
            });
          };
        }
        this.child(callback);
      }
      /**
       * @param {Array<() => void>} thunks
       */
      run(thunks) {
        const context2 = ssr_context;
        let promise = Promise.resolve(thunks[0]());
        const promises = [promise];
        for (const fn of thunks.slice(1)) {
          promise = promise.then(() => {
            const previous_context = ssr_context;
            set_ssr_context(context2);
            try {
              return fn();
            } finally {
              set_ssr_context(previous_context);
            }
          });
          promises.push(promise);
        }
        return promises;
      }
      /**
       * Create a child renderer. The child renderer inherits the state from the parent,
       * but has its own content.
       * @param {(renderer: Renderer) => MaybePromise<void>} fn
       */
      child(fn) {
        const child2 = new _Renderer(this.global, this);
        this.#out.push(child2);
        const parent = ssr_context;
        set_ssr_context({
          ...ssr_context,
          p: parent,
          c: null,
          r: child2
        });
        const result = fn(child2);
        set_ssr_context(parent);
        if (result instanceof Promise) {
          if (child2.global.mode === "sync") {
            await_invalid();
          }
          result.catch(() => {
          });
          child2.promise = result;
        }
        return child2;
      }
      /**
       * Create a component renderer. The component renderer inherits the state from the parent,
       * but has its own content. It is treated as an ordering boundary for ondestroy callbacks.
       * @param {(renderer: Renderer) => MaybePromise<void>} fn
       * @param {Function} [component_fn]
       * @returns {void}
       */
      component(fn, component_fn) {
        push2(component_fn);
        const child2 = this.child(fn);
        child2.#is_component_body = true;
        pop2();
      }
      /**
       * @param {Record<string, any>} attrs
       * @param {(renderer: Renderer) => void} fn
       * @param {string | undefined} [css_hash]
       * @param {Record<string, boolean> | undefined} [classes]
       * @param {Record<string, string> | undefined} [styles]
       * @param {number | undefined} [flags]
       * @returns {void}
       */
      select(attrs, fn, css_hash, classes, styles, flags2) {
        const { value, ...select_attrs } = attrs;
        this.push(`<select${attributes(select_attrs, css_hash, classes, styles, flags2)}>`);
        this.child((renderer) => {
          renderer.local.select_value = value;
          fn(renderer);
        });
        this.push("</select>");
      }
      /**
       * @param {Record<string, any>} attrs
       * @param {string | number | boolean | ((renderer: Renderer) => void)} body
       * @param {string | undefined} [css_hash]
       * @param {Record<string, boolean> | undefined} [classes]
       * @param {Record<string, string> | undefined} [styles]
       * @param {number | undefined} [flags]
       */
      option(attrs, body, css_hash, classes, styles, flags2) {
        this.#out.push(`<option${attributes(attrs, css_hash, classes, styles, flags2)}`);
        const close = (renderer, value, { head: head2, body: body2 }) => {
          if ("value" in attrs) {
            value = attrs.value;
          }
          if (value === this.local.select_value) {
            renderer.#out.push(" selected");
          }
          renderer.#out.push(`>${body2}</option>`);
          if (head2) {
            renderer.head((child2) => child2.push(head2));
          }
        };
        if (typeof body === "function") {
          this.child((renderer) => {
            const r2 = new _Renderer(this.global, this);
            body(r2);
            if (this.global.mode === "async") {
              return r2.#collect_content_async().then((content) => {
                close(renderer, content.body.replaceAll("<!---->", ""), content);
              });
            } else {
              const content = r2.#collect_content();
              close(renderer, content.body.replaceAll("<!---->", ""), content);
            }
          });
        } else {
          close(this, body, { body });
        }
      }
      /**
       * @param {(renderer: Renderer) => void} fn
       */
      title(fn) {
        const path = this.get_path();
        const close = (head2) => {
          this.global.set_title(head2, path);
        };
        this.child((renderer) => {
          const r2 = new _Renderer(renderer.global, renderer);
          fn(r2);
          if (renderer.global.mode === "async") {
            return r2.#collect_content_async().then((content) => {
              close(content.head);
            });
          } else {
            const content = r2.#collect_content();
            close(content.head);
          }
        });
      }
      /**
       * @param {string | (() => Promise<string>)} content
       */
      push(content) {
        if (typeof content === "function") {
          this.child(async (renderer) => renderer.push(await content()));
        } else {
          this.#out.push(content);
        }
      }
      /**
       * @param {() => void} fn
       */
      on_destroy(fn) {
        (this.#on_destroy ??= []).push(fn);
      }
      /**
       * @returns {number[]}
       */
      get_path() {
        return this.#parent ? [...this.#parent.get_path(), this.#parent.#out.indexOf(this)] : [];
      }
      /**
       * @deprecated this is needed for legacy component bindings
       */
      copy() {
        const copy = new _Renderer(this.global, this.#parent);
        copy.#out = this.#out.map((item) => item instanceof _Renderer ? item.copy() : item);
        copy.promise = this.promise;
        return copy;
      }
      /**
       * @param {Renderer} other
       * @deprecated this is needed for legacy component bindings
       */
      subsume(other) {
        if (this.global.mode !== other.global.mode) {
          throw new Error(
            "invariant: A renderer cannot switch modes. If you're seeing this, there's a compiler bug. File an issue!"
          );
        }
        this.local = other.local;
        this.#out = other.#out.map((item) => {
          if (item instanceof _Renderer) {
            item.subsume(item);
          }
          return item;
        });
        this.promise = other.promise;
        this.type = other.type;
      }
      get length() {
        return this.#out.length;
      }
      /**
       * Only available on the server and when compiling with the `server` option.
       * Takes a component and returns an object with `body` and `head` properties on it, which you can use to populate the HTML when server-rendering your app.
       * @template {Record<string, any>} Props
       * @param {Component<Props>} component
       * @param {{ props?: Omit<Props, '$$slots' | '$$events'>; context?: Map<any, any>; idPrefix?: string }} [options]
       * @returns {RenderOutput}
       */
      static render(component2, options = {}) {
        let sync;
        let async2;
        const result = (
          /** @type {RenderOutput} */
          {}
        );
        Object.defineProperties(result, {
          html: {
            get: () => {
              return (sync ??= _Renderer.#render(component2, options)).body;
            }
          },
          head: {
            get: () => {
              return (sync ??= _Renderer.#render(component2, options)).head;
            }
          },
          body: {
            get: () => {
              return (sync ??= _Renderer.#render(component2, options)).body;
            }
          },
          then: {
            value: (
              /**
               * this is not type-safe, but honestly it's the best I can do right now, and it's a straightforward function.
               *
               * @template TResult1
               * @template [TResult2=never]
               * @param { (value: SyncRenderOutput) => TResult1 } onfulfilled
               * @param { (reason: unknown) => TResult2 } onrejected
               */
              (onfulfilled, onrejected) => {
                if (!async_mode_flag) {
                  const result2 = sync ??= _Renderer.#render(component2, options);
                  const user_result = onfulfilled({
                    head: result2.head,
                    body: result2.body,
                    html: result2.body
                  });
                  return Promise.resolve(user_result);
                }
                async2 ??= init_render_context2().then(
                  () => with_render_context(() => _Renderer.#render_async(component2, options))
                );
                return async2.then((result2) => {
                  Object.defineProperty(result2, "html", {
                    // eslint-disable-next-line getter-return
                    get: () => {
                      html_deprecated();
                    }
                  });
                  return onfulfilled(
                    /** @type {SyncRenderOutput} */
                    result2
                  );
                }, onrejected);
              }
            )
          }
        });
        return result;
      }
      /**
       * Collect all of the `onDestroy` callbacks registered during rendering. In an async context, this is only safe to call
       * after awaiting `collect_async`.
       *
       * Child renderers are "porous" and don't affect execution order, but component body renderers
       * create ordering boundaries. Within a renderer, callbacks run in order until hitting a component boundary.
       * @returns {Iterable<() => void>}
       */
      *#collect_on_destroy() {
        for (const component2 of this.#traverse_components()) {
          yield* component2.#collect_ondestroy();
        }
      }
      /**
       * Performs a depth-first search of renderers, yielding the deepest components first, then additional components as we backtrack up the tree.
       * @returns {Iterable<Renderer>}
       */
      *#traverse_components() {
        for (const child2 of this.#out) {
          if (typeof child2 !== "string") {
            yield* child2.#traverse_components();
          }
        }
        if (this.#is_component_body) {
          yield this;
        }
      }
      /**
       * @returns {Iterable<() => void>}
       */
      *#collect_ondestroy() {
        if (this.#on_destroy) {
          for (const fn of this.#on_destroy) {
            yield fn;
          }
        }
        for (const child2 of this.#out) {
          if (child2 instanceof _Renderer && !child2.#is_component_body) {
            yield* child2.#collect_ondestroy();
          }
        }
      }
      /**
       * Render a component. Throws if any of the children are performing asynchronous work.
       *
       * @template {Record<string, any>} Props
       * @param {Component<Props>} component
       * @param {{ props?: Omit<Props, '$$slots' | '$$events'>; context?: Map<any, any>; idPrefix?: string }} options
       * @returns {AccumulatedContent}
       */
      static #render(component2, options) {
        var previous_context = ssr_context;
        try {
          const renderer = _Renderer.#open_render("sync", component2, options);
          const content = renderer.#collect_content();
          return _Renderer.#close_render(content, renderer);
        } finally {
          abort();
          set_ssr_context(previous_context);
        }
      }
      /**
       * Render a component.
       *
       * @template {Record<string, any>} Props
       * @param {Component<Props>} component
       * @param {{ props?: Omit<Props, '$$slots' | '$$events'>; context?: Map<any, any>; idPrefix?: string }} options
       * @returns {Promise<AccumulatedContent>}
       */
      static async #render_async(component2, options) {
        const previous_context = ssr_context;
        try {
          const renderer = _Renderer.#open_render("async", component2, options);
          const content = await renderer.#collect_content_async();
          const hydratables = await renderer.#collect_hydratables();
          if (hydratables !== null) {
            content.head = hydratables + content.head;
          }
          return _Renderer.#close_render(content, renderer);
        } finally {
          set_ssr_context(previous_context);
          abort();
        }
      }
      /**
       * Collect all of the code from the `out` array and return it as a string, or a promise resolving to a string.
       * @param {AccumulatedContent} content
       * @returns {AccumulatedContent}
       */
      #collect_content(content = { head: "", body: "" }) {
        for (const item of this.#out) {
          if (typeof item === "string") {
            content[this.type] += item;
          } else if (item instanceof _Renderer) {
            item.#collect_content(content);
          }
        }
        return content;
      }
      /**
       * Collect all of the code from the `out` array and return it as a string.
       * @param {AccumulatedContent} content
       * @returns {Promise<AccumulatedContent>}
       */
      async #collect_content_async(content = { head: "", body: "" }) {
        await this.promise;
        for (const item of this.#out) {
          if (typeof item === "string") {
            content[this.type] += item;
          } else if (item instanceof _Renderer) {
            await item.#collect_content_async(content);
          }
        }
        return content;
      }
      async #collect_hydratables() {
        const ctx = get_render_context().hydratable;
        for (const [_, key2] of ctx.unresolved_promises) {
          unresolved_hydratable(key2, ctx.lookup.get(key2)?.stack ?? "<missing stack trace>");
        }
        for (const comparison of ctx.comparisons) {
          await comparison;
        }
        return await _Renderer.#hydratable_block(ctx);
      }
      /**
       * @template {Record<string, any>} Props
       * @param {'sync' | 'async'} mode
       * @param {import('svelte').Component<Props>} component
       * @param {{ props?: Omit<Props, '$$slots' | '$$events'>; context?: Map<any, any>; idPrefix?: string }} options
       * @returns {Renderer}
       */
      static #open_render(mode, component2, options) {
        const renderer = new _Renderer(
          new SSRState(mode, options.idPrefix ? options.idPrefix + "-" : "")
        );
        renderer.push(BLOCK_OPEN);
        if (options.context) {
          push2();
          ssr_context.c = options.context;
          ssr_context.r = renderer;
        }
        component2(renderer, options.props ?? {});
        if (options.context) {
          pop2();
        }
        renderer.push(BLOCK_CLOSE);
        return renderer;
      }
      /**
       * @param {AccumulatedContent} content
       * @param {Renderer} renderer
       */
      static #close_render(content, renderer) {
        for (const cleanup of renderer.#collect_on_destroy()) {
          cleanup();
        }
        let head2 = content.head + renderer.global.get_title();
        let body = content.body;
        for (const { hash: hash2, code } of renderer.global.css) {
          head2 += `<style id="${hash2}">${code}</style>`;
        }
        return {
          head: head2,
          body
        };
      }
      /**
       * @param {HydratableContext} ctx
       */
      static async #hydratable_block(ctx) {
        if (ctx.lookup.size === 0) {
          return null;
        }
        let entries = [];
        let has_promises = false;
        for (const [k, v] of ctx.lookup) {
          if (v.promises) {
            has_promises = true;
            for (const p of v.promises) await p;
          }
          entries.push(`[${JSON.stringify(k)},${v.serialized}]`);
        }
        let prelude = `const h = (window.__svelte ??= {}).h ??= new Map();`;
        if (has_promises) {
          prelude = `const r = (v) => Promise.resolve(v);
				${prelude}`;
        }
        return `
		<script>
			{
				${prelude}

				for (const [k, v] of [
					${entries.join(",\n					")}
				]) {
					h.set(k, v);
				}
			}
		</script>`;
      }
    };
    SSRState = class {
      /** @readonly @type {'sync' | 'async'} */
      mode;
      /** @readonly @type {() => string} */
      uid;
      /** @readonly @type {Set<{ hash: string; code: string }>} */
      css = /* @__PURE__ */ new Set();
      /** @type {{ path: number[], value: string }} */
      #title = { path: [], value: "" };
      /**
       * @param {'sync' | 'async'} mode
       * @param {string} [id_prefix]
       */
      constructor(mode, id_prefix = "") {
        this.mode = mode;
        let uid = 1;
        this.uid = () => `${id_prefix}s${uid++}`;
      }
      get_title() {
        return this.#title.value;
      }
      /**
       * Performs a depth-first (lexicographic) comparison using the path. Rejects sets
       * from earlier than or equal to the current value.
       * @param {string} value
       * @param {number[]} path
       */
      set_title(value, path) {
        const current = this.#title.path;
        let i = 0;
        let l = Math.min(path.length, current.length);
        while (i < l && path[i] === current[i]) i += 1;
        if (path[i] === void 0) return;
        if (current[i] === void 0 || path[i] > current[i]) {
          this.#title.path = path;
          this.#title.value = value;
        }
      }
    };
  }
});

// node_modules/svelte/src/internal/server/blocks/html.js
var init_html2 = __esm({
  "node_modules/svelte/src/internal/server/blocks/html.js"() {
    init_esm_env();
    init_utils2();
  }
});

// node_modules/svelte/src/html-tree-validation.js
function is_tag_valid_with_ancestor(child_tag, ancestors, child_loc, ancestor_loc) {
  if (child_tag.includes("-")) return null;
  const ancestor_tag = ancestors[ancestors.length - 1];
  const disallowed = disallowed_children[ancestor_tag];
  if (!disallowed) return null;
  if ("reset_by" in disallowed && disallowed.reset_by) {
    for (let i = ancestors.length - 2; i >= 0; i--) {
      const ancestor = ancestors[i];
      if (ancestor.includes("-")) return null;
      if (disallowed.reset_by.includes(ancestors[i])) {
        return null;
      }
    }
  }
  if ("descendant" in disallowed && disallowed.descendant.includes(child_tag)) {
    const child2 = child_loc ? `\`<${child_tag}>\` (${child_loc})` : `\`<${child_tag}>\``;
    const ancestor = ancestor_loc ? `\`<${ancestor_tag}>\` (${ancestor_loc})` : `\`<${ancestor_tag}>\``;
    return `${child2} cannot be a descendant of ${ancestor}`;
  }
  return null;
}
function is_tag_valid_with_parent(child_tag, parent_tag, child_loc, parent_loc) {
  if (child_tag.includes("-") || parent_tag?.includes("-")) return null;
  if (parent_tag === "template") return null;
  const disallowed = disallowed_children[parent_tag];
  const child2 = child_loc ? `\`<${child_tag}>\` (${child_loc})` : `\`<${child_tag}>\``;
  const parent = parent_loc ? `\`<${parent_tag}>\` (${parent_loc})` : `\`<${parent_tag}>\``;
  if (disallowed) {
    if ("direct" in disallowed && disallowed.direct.includes(child_tag)) {
      return `${child2} cannot be a direct child of ${parent}`;
    }
    if ("descendant" in disallowed && disallowed.descendant.includes(child_tag)) {
      return `${child2} cannot be a child of ${parent}`;
    }
    if ("only" in disallowed && disallowed.only) {
      if (disallowed.only.includes(child_tag)) {
        return null;
      } else {
        return `${child2} cannot be a child of ${parent}. \`<${parent_tag}>\` only allows these children: ${disallowed.only.map((d) => `\`<${d}>\``).join(", ")}`;
      }
    }
  }
  switch (child_tag) {
    case "body":
    case "caption":
    case "col":
    case "colgroup":
    case "frameset":
    case "frame":
    case "head":
    case "html":
      return `${child2} cannot be a child of ${parent}`;
    case "thead":
    case "tbody":
    case "tfoot":
      return `${child2} must be the child of a \`<table>\`, not a ${parent}`;
    case "td":
    case "th":
      return `${child2} must be the child of a \`<tr>\`, not a ${parent}`;
    case "tr":
      return `\`<tr>\` must be the child of a \`<thead>\`, \`<tbody>\`, or \`<tfoot>\`, not a ${parent}`;
  }
  return null;
}
var autoclosing_children, disallowed_children;
var init_html_tree_validation = __esm({
  "node_modules/svelte/src/html-tree-validation.js"() {
    autoclosing_children = {
      // based on http://developers.whatwg.org/syntax.html#syntax-tag-omission
      li: { direct: ["li"] },
      // https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dt#technical_summary
      dt: { descendant: ["dt", "dd"], reset_by: ["dl"] },
      dd: { descendant: ["dt", "dd"], reset_by: ["dl"] },
      p: {
        descendant: [
          "address",
          "article",
          "aside",
          "blockquote",
          "div",
          "dl",
          "fieldset",
          "footer",
          "form",
          "h1",
          "h2",
          "h3",
          "h4",
          "h5",
          "h6",
          "header",
          "hgroup",
          "hr",
          "main",
          "menu",
          "nav",
          "ol",
          "p",
          "pre",
          "section",
          "table",
          "ul"
        ]
      },
      rt: { descendant: ["rt", "rp"] },
      rp: { descendant: ["rt", "rp"] },
      optgroup: { descendant: ["optgroup"] },
      option: { descendant: ["option", "optgroup"] },
      thead: { direct: ["tbody", "tfoot"] },
      tbody: { direct: ["tbody", "tfoot"] },
      tfoot: { direct: ["tbody"] },
      tr: { direct: ["tr", "tbody"] },
      td: { direct: ["td", "th", "tr"] },
      th: { direct: ["td", "th", "tr"] }
    };
    disallowed_children = {
      ...autoclosing_children,
      optgroup: { only: ["option", "#text"] },
      // Strictly speaking, seeing an <option> doesn't mean we're in a <select>, but we assume it here
      option: { only: ["#text"] },
      form: { descendant: ["form"] },
      a: { descendant: ["a"] },
      button: { descendant: ["button"] },
      h1: { descendant: ["h1", "h2", "h3", "h4", "h5", "h6"] },
      h2: { descendant: ["h1", "h2", "h3", "h4", "h5", "h6"] },
      h3: { descendant: ["h1", "h2", "h3", "h4", "h5", "h6"] },
      h4: { descendant: ["h1", "h2", "h3", "h4", "h5", "h6"] },
      h5: { descendant: ["h1", "h2", "h3", "h4", "h5", "h6"] },
      h6: { descendant: ["h1", "h2", "h3", "h4", "h5", "h6"] },
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inselect
      select: { only: ["option", "optgroup", "#text", "hr", "script", "template"] },
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intd
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-incaption
      // No special behavior since these rules fall back to "in body" mode for
      // all except special table nodes which cause bad parsing behavior anyway.
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intd
      tr: { only: ["th", "td", "style", "script", "template"] },
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intbody
      tbody: { only: ["tr", "style", "script", "template"] },
      thead: { only: ["tr", "style", "script", "template"] },
      tfoot: { only: ["tr", "style", "script", "template"] },
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-incolgroup
      colgroup: { only: ["col", "template"] },
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intable
      table: {
        only: ["caption", "colgroup", "tbody", "thead", "tfoot", "style", "script", "template"]
      },
      // https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inhead
      head: {
        only: [
          "base",
          "basefont",
          "bgsound",
          "link",
          "meta",
          "title",
          "noscript",
          "noframes",
          "style",
          "script",
          "template"
        ]
      },
      // https://html.spec.whatwg.org/multipage/semantics.html#the-html-element
      html: { only: ["head", "body", "frameset"] },
      frameset: { only: ["frame"] },
      "#document": { only: ["html"] }
    };
  }
});

// node_modules/svelte/src/internal/server/dev.js
function print_error(renderer, message) {
  message = `node_invalid_placement_ssr: ${message}

This can cause content to shift around as the browser repairs the HTML, and will likely result in a \`hydration_mismatch\` warning.`;
  if ((seen ??= /* @__PURE__ */ new Set()).has(message)) return;
  seen.add(message);
  console.error(message);
  renderer.head((r2) => r2.push(`<script>console.error(${JSON.stringify(message)})</script>`));
}
function push_element(renderer, tag2, line, column) {
  var context2 = (
    /** @type {SSRContext} */
    ssr_context
  );
  var filename = context2.function[FILENAME];
  var parent = context2.element;
  var element2 = { tag: tag2, parent, filename, line, column };
  if (parent !== void 0) {
    var ancestor = parent.parent;
    var ancestors = [parent.tag];
    const child_loc = filename ? `${filename}:${line}:${column}` : void 0;
    const parent_loc = parent.filename ? `${parent.filename}:${parent.line}:${parent.column}` : void 0;
    const message = is_tag_valid_with_parent(tag2, parent.tag, child_loc, parent_loc);
    if (message) print_error(renderer, message);
    while (ancestor != null) {
      ancestors.push(ancestor.tag);
      const ancestor_loc = ancestor.filename ? `${ancestor.filename}:${ancestor.line}:${ancestor.column}` : void 0;
      const message2 = is_tag_valid_with_ancestor(tag2, ancestors, child_loc, ancestor_loc);
      if (message2) print_error(renderer, message2);
      ancestor = ancestor.parent;
    }
  }
  set_ssr_context({ ...context2, p: context2, element: element2 });
}
function pop_element() {
  set_ssr_context(
    /** @type {SSRContext} */
    ssr_context.p
  );
}
function get_user_code_location() {
  const stack2 = get_stack();
  return stack2.filter((line) => line.trim().startsWith("at ")).map((line) => line.replace(/\((.*):\d+:\d+\)$/, (_, file) => `(${file})`)).join("\n");
}
var seen;
var init_dev2 = __esm({
  "node_modules/svelte/src/internal/server/dev.js"() {
    init_constants();
    init_html_tree_validation();
    init_dev();
    init_context2();
    init_errors3();
    init_renderer();
  }
});

// node_modules/svelte/src/internal/server/index.js
function render(component2, options = {}) {
  return Renderer.render(
    /** @type {Component<Props>} */
    component2,
    options
  );
}
function attributes(attrs, css_hash, classes, styles, flags2 = 0) {
  if (styles) {
    attrs.style = to_style(attrs.style, styles);
  }
  if (attrs.class) {
    attrs.class = clsx2(attrs.class);
  }
  if (css_hash || classes) {
    attrs.class = to_class(attrs.class, css_hash, classes);
  }
  let attr_str = "";
  let name;
  const is_html = (flags2 & ELEMENT_IS_NAMESPACED) === 0;
  const lowercase = (flags2 & ELEMENT_PRESERVE_ATTRIBUTE_CASE) === 0;
  const is_input = (flags2 & ELEMENT_IS_INPUT) !== 0;
  for (name in attrs) {
    if (typeof attrs[name] === "function") continue;
    if (name[0] === "$" && name[1] === "$") continue;
    if (INVALID_ATTR_NAME_CHAR_REGEX.test(name)) continue;
    var value = attrs[name];
    if (lowercase) {
      name = name.toLowerCase();
    }
    if (is_input) {
      if (name === "defaultvalue" || name === "defaultchecked") {
        name = name === "defaultvalue" ? "value" : "checked";
        if (attrs[name]) continue;
      }
    }
    attr_str += attr(name, value, is_html && is_boolean_attribute(name));
  }
  return attr_str;
}
function stringify(value) {
  return typeof value === "string" ? value : value == null ? "" : value + "";
}
function attr_class(value, hash2, directives) {
  var result = to_class(value, hash2, directives);
  return result ? ` class="${escape_html(result, true)}"` : "";
}
function attr_style(value, directives) {
  var result = to_style(value, directives);
  return result ? ` style="${escape_html(result, true)}"` : "";
}
function bind_props(props_parent, props_now) {
  for (const key2 in props_now) {
    const initial_value = props_parent[key2];
    const value = props_now[key2];
    if (initial_value === void 0 && value !== void 0 && Object.getOwnPropertyDescriptor(props_parent, key2)?.set) {
      props_parent[key2] = value;
    }
  }
}
function ensure_array_like(array_like_or_iterator) {
  if (array_like_or_iterator) {
    return array_like_or_iterator.length !== void 0 ? array_like_or_iterator : Array.from(array_like_or_iterator);
  }
  return [];
}
var INVALID_ATTR_NAME_CHAR_REGEX;
var init_server = __esm({
  "node_modules/svelte/src/internal/server/index.js"() {
    init_constants();
    init_attributes();
    init_utils();
    init_utils3();
    init_constants();
    init_escaping();
    init_esm_env();
    init_hydration2();
    init_validate();
    init_utils2();
    init_renderer();
    init_html2();
    init_context2();
    init_dev2();
    init_clone();
    init_utils();
    init_validate();
    INVALID_ATTR_NAME_CHAR_REGEX = /[\s'">/=\u{FDD0}-\u{FDEF}\u{FFFE}\u{FFFF}\u{1FFFE}\u{1FFFF}\u{2FFFE}\u{2FFFF}\u{3FFFE}\u{3FFFF}\u{4FFFE}\u{4FFFF}\u{5FFFE}\u{5FFFF}\u{6FFFE}\u{6FFFF}\u{7FFFE}\u{7FFFF}\u{8FFFE}\u{8FFFF}\u{9FFFE}\u{9FFFF}\u{AFFFE}\u{AFFFF}\u{BFFFE}\u{BFFFF}\u{CFFFE}\u{CFFFF}\u{DFFFE}\u{DFFFF}\u{EFFFE}\u{EFFFF}\u{FFFFE}\u{FFFFF}\u{10FFFE}\u{10FFFF}]/u;
  }
});

// node_modules/devalue/src/utils.js
function is_primitive(thing) {
  return Object(thing) !== thing;
}
function is_plain_object(thing) {
  const proto = Object.getPrototypeOf(thing);
  return proto === Object.prototype || proto === null || Object.getPrototypeOf(proto) === null || Object.getOwnPropertyNames(proto).sort().join("\0") === object_proto_names;
}
function get_type2(thing) {
  return Object.prototype.toString.call(thing).slice(8, -1);
}
function get_escaped_char(char) {
  switch (char) {
    case '"':
      return '\\"';
    case "<":
      return "\\u003C";
    case "\\":
      return "\\\\";
    case "\n":
      return "\\n";
    case "\r":
      return "\\r";
    case "	":
      return "\\t";
    case "\b":
      return "\\b";
    case "\f":
      return "\\f";
    case "\u2028":
      return "\\u2028";
    case "\u2029":
      return "\\u2029";
    default:
      return char < " " ? `\\u${char.charCodeAt(0).toString(16).padStart(4, "0")}` : "";
  }
}
function stringify_string(str) {
  let result = "";
  let last_pos = 0;
  const len = str.length;
  for (let i = 0; i < len; i += 1) {
    const char = str[i];
    const replacement = get_escaped_char(char);
    if (replacement) {
      result += str.slice(last_pos, i) + replacement;
      last_pos = i + 1;
    }
  }
  return `"${last_pos === 0 ? str : result + str.slice(last_pos)}"`;
}
function enumerable_symbols(object) {
  return Object.getOwnPropertySymbols(object).filter(
    (symbol) => Object.getOwnPropertyDescriptor(object, symbol).enumerable
  );
}
function stringify_key(key2) {
  return is_identifier.test(key2) ? "." + key2 : "[" + JSON.stringify(key2) + "]";
}
var escaped, DevalueError, object_proto_names, is_identifier;
var init_utils4 = __esm({
  "node_modules/devalue/src/utils.js"() {
    escaped = {
      "<": "\\u003C",
      "\\": "\\\\",
      "\b": "\\b",
      "\f": "\\f",
      "\n": "\\n",
      "\r": "\\r",
      "	": "\\t",
      "\u2028": "\\u2028",
      "\u2029": "\\u2029"
    };
    DevalueError = class extends Error {
      /**
       * @param {string} message
       * @param {string[]} keys
       */
      constructor(message, keys) {
        super(message);
        this.name = "DevalueError";
        this.path = keys.join("");
      }
    };
    object_proto_names = /* @__PURE__ */ Object.getOwnPropertyNames(
      Object.prototype
    ).sort().join("\0");
    is_identifier = /^[a-zA-Z_$][a-zA-Z_$0-9]*$/;
  }
});

// node_modules/devalue/src/uneval.js
function uneval(value, replacer) {
  const counts = /* @__PURE__ */ new Map();
  const keys = [];
  const custom = /* @__PURE__ */ new Map();
  function walk(thing) {
    if (!is_primitive(thing)) {
      if (counts.has(thing)) {
        counts.set(thing, counts.get(thing) + 1);
        return;
      }
      counts.set(thing, 1);
      if (replacer) {
        const str2 = replacer(thing, (value2) => uneval(value2, replacer));
        if (typeof str2 === "string") {
          custom.set(thing, str2);
          return;
        }
      }
      if (typeof thing === "function") {
        throw new DevalueError(`Cannot stringify a function`, keys);
      }
      const type = get_type2(thing);
      switch (type) {
        case "Number":
        case "BigInt":
        case "String":
        case "Boolean":
        case "Date":
        case "RegExp":
        case "URL":
        case "URLSearchParams":
          return;
        case "Array":
          thing.forEach((value2, i) => {
            keys.push(`[${i}]`);
            walk(value2);
            keys.pop();
          });
          break;
        case "Set":
          Array.from(thing).forEach(walk);
          break;
        case "Map":
          for (const [key2, value2] of thing) {
            keys.push(
              `.get(${is_primitive(key2) ? stringify_primitive(key2) : "..."})`
            );
            walk(value2);
            keys.pop();
          }
          break;
        case "Int8Array":
        case "Uint8Array":
        case "Uint8ClampedArray":
        case "Int16Array":
        case "Uint16Array":
        case "Int32Array":
        case "Uint32Array":
        case "Float32Array":
        case "Float64Array":
        case "BigInt64Array":
        case "BigUint64Array":
          walk(thing.buffer);
          return;
        case "ArrayBuffer":
          return;
        case "Temporal.Duration":
        case "Temporal.Instant":
        case "Temporal.PlainDate":
        case "Temporal.PlainTime":
        case "Temporal.PlainDateTime":
        case "Temporal.PlainMonthDay":
        case "Temporal.PlainYearMonth":
        case "Temporal.ZonedDateTime":
          return;
        default:
          if (!is_plain_object(thing)) {
            throw new DevalueError(
              `Cannot stringify arbitrary non-POJOs`,
              keys
            );
          }
          if (enumerable_symbols(thing).length > 0) {
            throw new DevalueError(
              `Cannot stringify POJOs with symbolic keys`,
              keys
            );
          }
          for (const key2 in thing) {
            keys.push(stringify_key(key2));
            walk(thing[key2]);
            keys.pop();
          }
      }
    }
  }
  walk(value);
  const names = /* @__PURE__ */ new Map();
  Array.from(counts).filter((entry) => entry[1] > 1).sort((a, b) => b[1] - a[1]).forEach((entry, i) => {
    names.set(entry[0], get_name(i));
  });
  function stringify2(thing) {
    if (names.has(thing)) {
      return names.get(thing);
    }
    if (is_primitive(thing)) {
      return stringify_primitive(thing);
    }
    if (custom.has(thing)) {
      return custom.get(thing);
    }
    const type = get_type2(thing);
    switch (type) {
      case "Number":
      case "String":
      case "Boolean":
        return `Object(${stringify2(thing.valueOf())})`;
      case "RegExp":
        return `new RegExp(${stringify_string(thing.source)}, "${thing.flags}")`;
      case "Date":
        return `new Date(${thing.getTime()})`;
      case "URL":
        return `new URL(${stringify_string(thing.toString())})`;
      case "URLSearchParams":
        return `new URLSearchParams(${stringify_string(thing.toString())})`;
      case "Array":
        const members = (
          /** @type {any[]} */
          thing.map(
            (v, i) => i in thing ? stringify2(v) : ""
          )
        );
        const tail = thing.length === 0 || thing.length - 1 in thing ? "" : ",";
        return `[${members.join(",")}${tail}]`;
      case "Set":
      case "Map":
        return `new ${type}([${Array.from(thing).map(stringify2).join(",")}])`;
      case "Int8Array":
      case "Uint8Array":
      case "Uint8ClampedArray":
      case "Int16Array":
      case "Uint16Array":
      case "Int32Array":
      case "Uint32Array":
      case "Float32Array":
      case "Float64Array":
      case "BigInt64Array":
      case "BigUint64Array": {
        let str2 = `new ${type}`;
        if (counts.get(thing.buffer) === 1) {
          const array = new thing.constructor(thing.buffer);
          str2 += `([${array}])`;
        } else {
          str2 += `([${stringify2(thing.buffer)}])`;
        }
        const a = thing.byteOffset;
        const b = a + thing.byteLength;
        if (a > 0 || b !== thing.buffer.byteLength) {
          const m = +/(\d+)/.exec(type)[1] / 8;
          str2 += `.subarray(${a / m},${b / m})`;
        }
        return str2;
      }
      case "ArrayBuffer": {
        const ui8 = new Uint8Array(thing);
        return `new Uint8Array([${ui8.toString()}]).buffer`;
      }
      case "Temporal.Duration":
      case "Temporal.Instant":
      case "Temporal.PlainDate":
      case "Temporal.PlainTime":
      case "Temporal.PlainDateTime":
      case "Temporal.PlainMonthDay":
      case "Temporal.PlainYearMonth":
      case "Temporal.ZonedDateTime":
        return `${type}.from(${stringify_string(thing.toString())})`;
      default:
        const keys2 = Object.keys(thing);
        const obj = keys2.map((key2) => `${safe_key(key2)}:${stringify2(thing[key2])}`).join(",");
        const proto = Object.getPrototypeOf(thing);
        if (proto === null) {
          return keys2.length > 0 ? `{${obj},__proto__:null}` : `{__proto__:null}`;
        }
        return `{${obj}}`;
    }
  }
  const str = stringify2(value);
  if (names.size) {
    const params = [];
    const statements = [];
    const values = [];
    names.forEach((name, thing) => {
      params.push(name);
      if (custom.has(thing)) {
        values.push(
          /** @type {string} */
          custom.get(thing)
        );
        return;
      }
      if (is_primitive(thing)) {
        values.push(stringify_primitive(thing));
        return;
      }
      const type = get_type2(thing);
      switch (type) {
        case "Number":
        case "String":
        case "Boolean":
          values.push(`Object(${stringify2(thing.valueOf())})`);
          break;
        case "RegExp":
          values.push(thing.toString());
          break;
        case "Date":
          values.push(`new Date(${thing.getTime()})`);
          break;
        case "Array":
          values.push(`Array(${thing.length})`);
          thing.forEach((v, i) => {
            statements.push(`${name}[${i}]=${stringify2(v)}`);
          });
          break;
        case "Set":
          values.push(`new Set`);
          statements.push(
            `${name}.${Array.from(thing).map((v) => `add(${stringify2(v)})`).join(".")}`
          );
          break;
        case "Map":
          values.push(`new Map`);
          statements.push(
            `${name}.${Array.from(thing).map(([k, v]) => `set(${stringify2(k)}, ${stringify2(v)})`).join(".")}`
          );
          break;
        case "ArrayBuffer":
          values.push(
            `new Uint8Array([${new Uint8Array(thing).join(",")}]).buffer`
          );
          break;
        default:
          values.push(
            Object.getPrototypeOf(thing) === null ? "Object.create(null)" : "{}"
          );
          Object.keys(thing).forEach((key2) => {
            statements.push(
              `${name}${safe_prop(key2)}=${stringify2(thing[key2])}`
            );
          });
      }
    });
    statements.push(`return ${str}`);
    return `(function(${params.join(",")}){${statements.join(
      ";"
    )}}(${values.join(",")}))`;
  } else {
    return str;
  }
}
function get_name(num) {
  let name = "";
  do {
    name = chars[num % chars.length] + name;
    num = ~~(num / chars.length) - 1;
  } while (num >= 0);
  return reserved.test(name) ? `${name}0` : name;
}
function escape_unsafe_char(c) {
  return escaped[c] || c;
}
function escape_unsafe_chars(str) {
  return str.replace(unsafe_chars, escape_unsafe_char);
}
function safe_key(key2) {
  return /^[_$a-zA-Z][_$a-zA-Z0-9]*$/.test(key2) ? key2 : escape_unsafe_chars(JSON.stringify(key2));
}
function safe_prop(key2) {
  return /^[_$a-zA-Z][_$a-zA-Z0-9]*$/.test(key2) ? `.${key2}` : `[${escape_unsafe_chars(JSON.stringify(key2))}]`;
}
function stringify_primitive(thing) {
  if (typeof thing === "string") return stringify_string(thing);
  if (thing === void 0) return "void 0";
  if (thing === 0 && 1 / thing < 0) return "-0";
  const str = String(thing);
  if (typeof thing === "number") return str.replace(/^(-)?0\./, "$1.");
  if (typeof thing === "bigint") return thing + "n";
  return str;
}
var chars, unsafe_chars, reserved;
var init_uneval = __esm({
  "node_modules/devalue/src/uneval.js"() {
    init_utils4();
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$";
    unsafe_chars = /[<\b\f\n\r\t\0\u2028\u2029]/g;
    reserved = /^(?:do|if|in|for|int|let|new|try|var|byte|case|char|else|enum|goto|long|this|void|with|await|break|catch|class|const|final|float|short|super|throw|while|yield|delete|double|export|import|native|return|switch|throws|typeof|boolean|default|extends|finally|package|private|abstract|continue|debugger|function|volatile|interface|protected|transient|implements|instanceof|synchronized)$/;
  }
});

// node_modules/devalue/index.js
var init_devalue = __esm({
  "node_modules/devalue/index.js"() {
    init_uneval();
  }
});

// node_modules/svelte/src/internal/server/hydratable.js
function hydratable2(key2, fn) {
  if (!async_mode_flag) {
    experimental_async_required("hydratable");
  }
  const { hydratable: hydratable3 } = get_render_context();
  let entry = hydratable3.lookup.get(key2);
  if (entry !== void 0) {
    if (true_default) {
      const comparison = compare2(key2, entry, encode(key2, fn()));
      comparison.catch(() => {
      });
      hydratable3.comparisons.push(comparison);
    }
    return (
      /** @type {T} */
      entry.value
    );
  }
  const value = fn();
  entry = encode(key2, value, hydratable3.unresolved_promises);
  hydratable3.lookup.set(key2, entry);
  return value;
}
function encode(key2, value, unresolved) {
  const entry = { value, serialized: "" };
  if (true_default) {
    entry.stack = get_user_code_location();
  }
  let uid = 1;
  entry.serialized = uneval(entry.value, (value2, uneval2) => {
    if (is_promise2(value2)) {
      const p = value2.then((v) => `r(${uneval2(v)})`).catch(
        (devalue_error) => hydratable_serialization_failed(
          key2,
          serialization_stack(entry.stack, devalue_error?.stack)
        )
      );
      p.catch(() => {
      });
      unresolved?.set(p, key2);
      p.finally(() => unresolved?.delete(p));
      const placeholder = `"${uid++}"`;
      (entry.promises ??= []).push(
        p.then((s) => {
          entry.serialized = entry.serialized.replace(placeholder, s);
        })
      );
      return placeholder;
    }
  });
  return entry;
}
function is_promise2(value) {
  return Object.prototype.toString.call(value) === "[object Promise]";
}
async function compare2(key2, a, b) {
  for (const p of a?.promises ?? []) {
    await p;
  }
  for (const p of b?.promises ?? []) {
    await p;
  }
  if (a.serialized !== b.serialized) {
    const a_stack = (
      /** @type {string} */
      a.stack
    );
    const b_stack = (
      /** @type {string} */
      b.stack
    );
    const stack2 = a_stack === b_stack ? `Occurred at:
${a_stack}` : `First occurrence at:
${a_stack}

Second occurrence at:
${b_stack}`;
    hydratable_clobbering(key2, stack2);
  }
}
function serialization_stack(root_stack, uneval_stack) {
  let out = "";
  if (root_stack) {
    out += root_stack + "\n";
  }
  if (uneval_stack) {
    out += "Caused by:\n" + uneval_stack + "\n";
  }
  return out || "<missing stack trace>";
}
var init_hydratable2 = __esm({
  "node_modules/svelte/src/internal/server/hydratable.js"() {
    init_flags();
    init_render_context();
    init_errors3();
    init_devalue();
    init_dev();
    init_esm_env();
    init_dev2();
  }
});

// node_modules/svelte/src/internal/server/blocks/snippet.js
function createRawSnippet2(fn) {
  return (renderer, ...args) => {
    var getters = (
      /** @type {Getters<Params>} */
      args.map((value) => () => value)
    );
    renderer.push(
      fn(...getters).render().trim()
    );
  };
}
var init_snippet2 = __esm({
  "node_modules/svelte/src/internal/server/blocks/snippet.js"() {
  }
});

// node_modules/svelte/src/index-server.js
var index_server_exports = {};
__export(index_server_exports, {
  afterUpdate: () => noop,
  beforeUpdate: () => noop,
  createContext: () => createContext2,
  createEventDispatcher: () => createEventDispatcher,
  createRawSnippet: () => createRawSnippet2,
  flushSync: () => noop,
  fork: () => fork2,
  getAbortSignal: () => getAbortSignal,
  getAllContexts: () => getAllContexts2,
  getContext: () => getContext2,
  hasContext: () => hasContext2,
  hydratable: () => hydratable2,
  hydrate: () => hydrate2,
  mount: () => mount2,
  onDestroy: () => onDestroy,
  onMount: () => noop,
  setContext: () => setContext2,
  settled: () => settled2,
  tick: () => tick2,
  unmount: () => unmount2,
  untrack: () => run
});
function onDestroy(fn) {
  /** @type {SSRContext} */
  ssr_context.r.on_destroy(fn);
}
function createEventDispatcher() {
  return noop;
}
function mount2() {
  lifecycle_function_unavailable("mount");
}
function hydrate2() {
  lifecycle_function_unavailable("hydrate");
}
function unmount2() {
  lifecycle_function_unavailable("unmount");
}
function fork2() {
  lifecycle_function_unavailable("fork");
}
async function tick2() {
}
async function settled2() {
}
var init_index_server = __esm({
  "node_modules/svelte/src/index-server.js"() {
    init_context2();
    init_utils();
    init_errors3();
    init_utils();
    init_abort_signal();
    init_context2();
    init_hydratable2();
    init_snippet2();
  }
});

// node_modules/svelte/src/server/index.js
var server_exports2 = {};
__export(server_exports2, {
  render: () => render
});
var init_server2 = __esm({
  "node_modules/svelte/src/server/index.js"() {
    init_server();
  }
});

// ../deps/live_svelte/priv/static/live_svelte.cjs.js
var require_live_svelte_cjs = __commonJS({
  "../deps/live_svelte/priv/static/live_svelte.cjs.js"(exports2, module2) {
    var __create2 = Object.create;
    var __defProp2 = Object.defineProperty;
    var __getOwnPropDesc2 = Object.getOwnPropertyDescriptor;
    var __getOwnPropNames2 = Object.getOwnPropertyNames;
    var __getProtoOf2 = Object.getPrototypeOf;
    var __hasOwnProp2 = Object.prototype.hasOwnProperty;
    var __export2 = (target, all) => {
      for (var name in all)
        __defProp2(target, name, { get: all[name], enumerable: true });
    };
    var __copyProps2 = (to, from, except, desc) => {
      if (from && typeof from === "object" || typeof from === "function") {
        for (let key2 of __getOwnPropNames2(from))
          if (!__hasOwnProp2.call(to, key2) && key2 !== except)
            __defProp2(to, key2, { get: () => from[key2], enumerable: !(desc = __getOwnPropDesc2(from, key2)) || desc.enumerable });
      }
      return to;
    };
    var __toESM2 = (mod, isNodeMode, target) => (target = mod != null ? __create2(__getProtoOf2(mod)) : {}, __copyProps2(
      // If the importer is in node compatibility mode or this is not an ESM
      // file that has been converted to a CommonJS file using a Babel-
      // compatible transform (i.e. "__esModule" has not been set), then set
      // "default" to the CommonJS "module.exports" for node compatibility.
      isNodeMode || !mod || !mod.__esModule ? __defProp2(target, "default", { value: mod, enumerable: true }) : target,
      mod
    ));
    var __toCommonJS2 = (mod) => __copyProps2(__defProp2({}, "__esModule", { value: true }), mod);
    var live_svelte_exports = {};
    __export2(live_svelte_exports, {
      getHooks: () => getHooks,
      getRender: () => getRender2
    });
    module2.exports = __toCommonJS2(live_svelte_exports);
    function normalizeComponents(components) {
      if (!Array.isArray(components.default) || !Array.isArray(components.filenames)) return components;
      const normalized = {};
      for (const [index2, module22] of components.default.entries()) {
        const Component = module22.default;
        const name = components.filenames[index2].replace("../svelte/", "").replace(".svelte", "");
        normalized[name] = Component;
      }
      return normalized;
    }
    var import_server2 = (init_server2(), __toCommonJS(server_exports2));
    var import_svelte4 = (init_index_server(), __toCommonJS(index_server_exports));
    function getRender2(components) {
      components = normalizeComponents(components);
      return function r2(name, props, slots) {
        const snippets = Object.fromEntries(
          Object.entries(slots).map(([slotName, v]) => {
            const snippet2 = (0, import_svelte4.createRawSnippet)((name2) => {
              return {
                render: () => v
              };
            });
            if (slotName === "default") return ["children", snippet2];
            else return [slotName, snippet2];
          })
        );
        return (0, import_server2.render)(components[name], { props: { ...props, ...snippets } });
      };
    }
    var $ = __toESM2((init_client(), __toCommonJS(client_exports)));
    var import_svelte22 = (init_index_server(), __toCommonJS(index_server_exports));
    function getAttributeJson(ref, attributeName) {
      const data = ref.el.getAttribute(attributeName);
      return data ? JSON.parse(data) : {};
    }
    function getSlots(ref) {
      let snippets = {};
      for (const slotName in getAttributeJson(ref, "data-slots")) {
        const base64 = getAttributeJson(ref, "data-slots")[slotName];
        const element2 = document.createElement("div");
        element2.innerHTML = atob(base64).trim();
        const snippet2 = (0, import_svelte22.createRawSnippet)((name) => {
          return { render: () => element2.outerHTML };
        });
        if (slotName === "default") snippets["children"] = snippet2;
        else snippets[slotName] = snippet2;
      }
      return snippets;
    }
    function getLiveJsonProps(ref) {
      const json = getAttributeJson(ref, "data-live-json");
      if (!Array.isArray(json)) return json;
      const liveJsonData = {};
      for (const liveJsonVariable of json) {
        const data = window[liveJsonVariable];
        if (data) liveJsonData[liveJsonVariable] = data;
      }
      return liveJsonData;
    }
    function getProps(ref) {
      return {
        ...getAttributeJson(ref, "data-props"),
        ...getLiveJsonProps(ref),
        ...getSlots(ref),
        live: ref
      };
    }
    function update_state(ref) {
      const newProps = getProps(ref);
      for (const key2 in newProps) {
        ref._instance.state[key2] = newProps[key2];
      }
    }
    function getHooks(components) {
      components = normalizeComponents(components);
      const SvelteHook = {
        mounted() {
          let state2 = $.proxy(getProps(this));
          const componentName = this.el.getAttribute("data-name");
          if (!componentName) throw new Error("Component name must be provided");
          const Component = components[componentName];
          if (!Component) throw new Error(`Unable to find ${componentName} component.`);
          for (const liveJsonElement of Object.keys(getAttributeJson(this, "data-live-json"))) {
            window.addEventListener(`${liveJsonElement}_initialized`, (_event) => update_state(this), false);
            window.addEventListener(`${liveJsonElement}_patched`, (_event) => update_state(this), false);
          }
          if (!this.el.hasAttribute("data-ssr")) {
            this.el.innerHTML = "";
          }
          const hydrateOrMount = this.el.hasAttribute("data-ssr") ? import_svelte22.hydrate : import_svelte22.mount;
          this._instance = hydrateOrMount(Component, { target: this.el, props: state2 });
          this._instance.state = state2;
        },
        updated() {
          update_state(this);
        },
        destroyed() {
          if (this._instance) window.addEventListener("phx:page-loading-stop", () => (0, import_svelte22.unmount)(this._instance), { once: true });
        }
      };
      return { SvelteHook };
    }
  }
});

// js/server.js
var server_exports3 = {};
__export(server_exports3, {
  render: () => render2
});
module.exports = __toCommonJS(server_exports3);

// import-glob:../svelte/**/*.svelte
var __exports = {};
__export(__exports, {
  default: () => __default,
  filenames: () => filenames
});

// svelte/CodeSnippetCard.svelte
var CodeSnippetCard_exports = {};
__export(CodeSnippetCard_exports, {
  default: () => CodeSnippetCard_default
});
init_server();
CodeSnippetCard[FILENAME] = "svelte/CodeSnippetCard.svelte";
function CodeSnippetCard($$renderer, $$props) {
  $$renderer.component(
    ($$renderer2) => {
      let delay = fallback($$props["delay"], 0);
      $$renderer2.push(`<div class="absolute hidden lg:block top-1/4 left-10 xl:left-32 w-64 bg-gray-900/90 backdrop-blur-xl border border-gray-700/50 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.1)] rounded-2xl p-4 animate-float rotate-[-3deg]"${attr_style(`animation-delay: ${stringify(delay)}s`)}>`);
      push_element($$renderer2, "div", 5, 0);
      $$renderer2.push(`<div class="font-mono text-[10px] text-gray-300 leading-relaxed">`);
      push_element($$renderer2, "div", 9, 2);
      $$renderer2.push(`<div class="flex gap-2 mb-2 border-b border-gray-700 pb-2">`);
      push_element($$renderer2, "div", 10, 4);
      $$renderer2.push(`<div class="w-2 h-2 rounded-full bg-red-500">`);
      push_element($$renderer2, "div", 11, 6);
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(` <div class="w-2 h-2 rounded-full bg-yellow-500">`);
      push_element($$renderer2, "div", 12, 6);
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(` <div class="w-2 h-2 rounded-full bg-green-500">`);
      push_element($$renderer2, "div", 13, 6);
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(` <div class="text-blue-400">`);
      push_element($$renderer2, "div", 15, 4);
      $$renderer2.push(`const <span class="text-yellow-200">`);
      push_element($$renderer2, "span", 16, 12);
      $$renderer2.push(`automate</span>`);
      pop_element();
      $$renderer2.push(` = <span class="text-purple-400">`);
      push_element($$renderer2, "span", 16, 60);
      $$renderer2.push(`async</span>`);
      pop_element();
      $$renderer2.push(` () => {</div>`);
      pop_element();
      $$renderer2.push(` <div class="pl-4">`);
      push_element($$renderer2, "div", 18, 4);
      $$renderer2.push(`await <span class="text-green-300">`);
      push_element($$renderer2, "span", 19, 12);
      $$renderer2.push(`n8n</span>`);
      pop_element();
      $$renderer2.push(`.trigger();</div>`);
      pop_element();
      $$renderer2.push(` <div class="pl-4">`);
      push_element($$renderer2, "div", 21, 4);
      $$renderer2.push(`return <span class="text-orange-300">`);
      push_element($$renderer2, "span", 22, 13);
      $$renderer2.push(`"Freedom"</span>`);
      pop_element();
      $$renderer2.push(`;</div>`);
      pop_element();
      $$renderer2.push(` <div>`);
      push_element($$renderer2, "div", 24, 4);
      $$renderer2.push(`}</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      bind_props($$props, { delay });
    },
    CodeSnippetCard
  );
}
CodeSnippetCard.render = function() {
  throw new Error("Component.render(...) is no longer valid in Svelte 5. See https://svelte.dev/docs/svelte/v5-migration-guide#Components-are-no-longer-classes for more information");
};
var CodeSnippetCard_default = CodeSnippetCard;

// svelte/Counter.svelte
var Counter_exports = {};
__export(Counter_exports, {
  default: () => Counter_default
});
init_server();
Counter[FILENAME] = "svelte/Counter.svelte";
function Counter($$renderer, $$props) {
  $$renderer.component(
    ($$renderer2) => {
      let count = fallback($$props["count"], 0);
      let live = $$props["live"];
      function increment2() {
        live.pushEvent("increment", {});
      }
      function decrement() {
        live.pushEvent("decrement", {});
      }
      $$renderer2.push(`<div class="flex flex-col items-center gap-4 p-8">`);
      push_element($$renderer2, "div", 14, 0);
      $$renderer2.push(`<h2 class="text-3xl font-bold">`);
      push_element($$renderer2, "h2", 15, 2);
      $$renderer2.push(`Counter: ${escape_html(count)}</h2>`);
      pop_element();
      $$renderer2.push(` <div class="flex gap-2">`);
      push_element($$renderer2, "div", 17, 2);
      $$renderer2.push(`<button class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 transition">`);
      push_element($$renderer2, "button", 18, 4);
      $$renderer2.push(`Decrement</button>`);
      pop_element();
      $$renderer2.push(` <button class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition">`);
      push_element($$renderer2, "button", 25, 4);
      $$renderer2.push(`Increment</button>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      bind_props($$props, { count, live });
    },
    Counter
  );
}
Counter.render = function() {
  throw new Error("Component.render(...) is no longer valid in Svelte 5. See https://svelte.dev/docs/svelte/v5-migration-guide#Components-are-no-longer-classes for more information");
};
var Counter_default = Counter;

// svelte/Navbar.svelte
var Navbar_exports = {};
__export(Navbar_exports, {
  default: () => Navbar_default
});
init_server();
init_index_server();

// svelte/ThemeSelector.svelte
var ThemeSelector_exports = {};
__export(ThemeSelector_exports, {
  default: () => ThemeSelector_default
});
init_server();
init_index_server();
ThemeSelector[FILENAME] = "svelte/ThemeSelector.svelte";
var $$css = {
  hash: "svelte-k618ps",
  code: "\n  .theme-selector.svelte-k618ps {\n    user-select: none;\n  }\n\n/*# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiVGhlbWVTZWxlY3Rvci5zdmVsdGUiLCJzb3VyY2VzIjpbIlRoZW1lU2VsZWN0b3Iuc3ZlbHRlIl0sInNvdXJjZXNDb250ZW50IjpbIjxzY3JpcHQ+XG4gIGltcG9ydCB7IG9uTW91bnQgfSBmcm9tICdzdmVsdGUnXG5cbiAgY29uc3QgdGhlbWVzID0gW1xuICAgIHsgdmFsdWU6ICdkYXJrJywgbGFiZWw6ICdEYXJrJywgaWNvbjogJ/CfjJknIH0sXG4gICAgeyB2YWx1ZTogJ2RyYWN1bGEnLCBsYWJlbDogJ0RyYWN1bGEnLCBpY29uOiAn8J+nmycgfSxcbiAgICB7IHZhbHVlOiAnc3ludGh3YXZlJywgbGFiZWw6ICdTeW50aHdhdmUnLCBpY29uOiAn8J+MhicgfSxcbiAgICB7IHZhbHVlOiAnYnVzaW5lc3MnLCBsYWJlbDogJ0J1c2luZXNzJywgaWNvbjogJ/CfkrwnIH0sXG4gICAgeyB2YWx1ZTogJ2RpbScsIGxhYmVsOiAnRGltJywgaWNvbjogJ/CfjJEnIH1cbiAgXVxuXG4gIGxldCBjdXJyZW50VGhlbWUgPSAnZGFyaydcbiAgbGV0IGlzT3BlbiA9IGZhbHNlXG5cbiAgZnVuY3Rpb24gYXBwbHlUaGVtZSh0aGVtZSkge1xuICAgIGN1cnJlbnRUaGVtZSA9IHRoZW1lXG4gICAgZG9jdW1lbnQuZG9jdW1lbnRFbGVtZW50LnNldEF0dHJpYnV0ZSgnZGF0YS10aGVtZScsIHRoZW1lKVxuICAgIGxvY2FsU3RvcmFnZS5zZXRJdGVtKCd0aGVtZScsIHRoZW1lKVxuICB9XG5cbiAgZnVuY3Rpb24gc2VsZWN0VGhlbWUodGhlbWUpIHtcbiAgICBhcHBseVRoZW1lKHRoZW1lKVxuICAgIGlzT3BlbiA9IGZhbHNlXG4gIH1cblxuICBmdW5jdGlvbiB0b2dnbGVEcm9wZG93bigpIHtcbiAgICBpc09wZW4gPSAhaXNPcGVuXG4gIH1cblxuICAvLyBDbG9zZSBkcm9wZG93biB3aGVuIGNsaWNraW5nIG91dHNpZGVcbiAgZnVuY3Rpb24gaGFuZGxlQ2xpY2tPdXRzaWRlKGV2ZW50KSB7XG4gICAgaWYgKCFldmVudC50YXJnZXQuY2xvc2VzdCgnLnRoZW1lLXNlbGVjdG9yJykpIHtcbiAgICAgIGlzT3BlbiA9IGZhbHNlXG4gICAgfVxuICB9XG5cbiAgb25Nb3VudCgoKSA9PiB7XG4gICAgLy8gUmVhZCBmcm9tIGxvY2FsU3RvcmFnZSBvciBkZWZhdWx0IHRvIGRhcmtcbiAgICBjb25zdCBzYXZlZFRoZW1lID0gbG9jYWxTdG9yYWdlLmdldEl0ZW0oJ3RoZW1lJykgfHwgJ2RhcmsnXG4gICAgYXBwbHlUaGVtZShzYXZlZFRoZW1lKVxuXG4gICAgLy8gQWRkIGNsaWNrIG91dHNpZGUgbGlzdGVuZXJcbiAgICBkb2N1bWVudC5hZGRFdmVudExpc3RlbmVyKCdjbGljaycsIGhhbmRsZUNsaWNrT3V0c2lkZSlcbiAgICByZXR1cm4gKCkgPT4gZG9jdW1lbnQucmVtb3ZlRXZlbnRMaXN0ZW5lcignY2xpY2snLCBoYW5kbGVDbGlja091dHNpZGUpXG4gIH0pXG48L3NjcmlwdD5cblxuPGRpdiBjbGFzcz1cInRoZW1lLXNlbGVjdG9yIHJlbGF0aXZlXCI+XG4gIDxidXR0b25cbiAgICBvbjpjbGljaz17dG9nZ2xlRHJvcGRvd259XG4gICAgY2xhc3M9XCJidG4gYnRuLWdob3N0IGJ0bi1zbSBnYXAtMlwiXG4gICAgYXJpYS1sYWJlbD1cIlNlbGVjdCB0aGVtZVwiXG4gID5cbiAgICA8c3BhbiBjbGFzcz1cInRleHQtbGdcIj57dGhlbWVzLmZpbmQodCA9PiB0LnZhbHVlID09PSBjdXJyZW50VGhlbWUpPy5pY29uIHx8ICfwn4yZJ308L3NwYW4+XG4gICAgPHNwYW4gY2xhc3M9XCJoaWRkZW4gbWQ6aW5saW5lXCI+VGhlbWU8L3NwYW4+XG4gICAgPHN2Z1xuICAgICAgeG1sbnM9XCJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Z1wiXG4gICAgICBjbGFzcz1cImgtNCB3LTQgdHJhbnNpdGlvbi10cmFuc2Zvcm0ge2lzT3BlbiA/ICdyb3RhdGUtMTgwJyA6ICcnfVwiXG4gICAgICBmaWxsPVwibm9uZVwiXG4gICAgICB2aWV3Qm94PVwiMCAwIDI0IDI0XCJcbiAgICAgIHN0cm9rZT1cImN1cnJlbnRDb2xvclwiXG4gICAgPlxuICAgICAgPHBhdGggc3Ryb2tlLWxpbmVjYXA9XCJyb3VuZFwiIHN0cm9rZS1saW5lam9pbj1cInJvdW5kXCIgc3Ryb2tlLXdpZHRoPVwiMlwiIGQ9XCJNMTkgOWwtNyA3LTctN1wiIC8+XG4gICAgPC9zdmc+XG4gIDwvYnV0dG9uPlxuXG4gIHsjaWYgaXNPcGVufVxuICAgIDxkaXYgY2xhc3M9XCJhYnNvbHV0ZSByaWdodC0wIG10LTIgdy00OCBiZy1iYXNlLTIwMCByb3VuZGVkLWxnIHNoYWRvdy14bCBib3JkZXIgYm9yZGVyLWJhc2UtMzAwIHotNTBcIj5cbiAgICAgIDx1bCBjbGFzcz1cIm1lbnUgcC0yXCI+XG4gICAgICAgIHsjZWFjaCB0aGVtZXMgYXMgdGhlbWV9XG4gICAgICAgICAgPGxpPlxuICAgICAgICAgICAgPGJ1dHRvblxuICAgICAgICAgICAgICBvbjpjbGljaz17KCkgPT4gc2VsZWN0VGhlbWUodGhlbWUudmFsdWUpfVxuICAgICAgICAgICAgICBjbGFzcz1cImZsZXggaXRlbXMtY2VudGVyIGdhcC0zIHtjdXJyZW50VGhlbWUgPT09IHRoZW1lLnZhbHVlID8gJ2FjdGl2ZSBiZy1wcmltYXJ5IHRleHQtcHJpbWFyeS1jb250ZW50JyA6ICcnfVwiXG4gICAgICAgICAgICA+XG4gICAgICAgICAgICAgIDxzcGFuIGNsYXNzPVwidGV4dC1sZ1wiPnt0aGVtZS5pY29ufTwvc3Bhbj5cbiAgICAgICAgICAgICAgPHNwYW4+e3RoZW1lLmxhYmVsfTwvc3Bhbj5cbiAgICAgICAgICAgICAgeyNpZiBjdXJyZW50VGhlbWUgPT09IHRoZW1lLnZhbHVlfVxuICAgICAgICAgICAgICAgIDxzdmdcbiAgICAgICAgICAgICAgICAgIHhtbG5zPVwiaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmdcIlxuICAgICAgICAgICAgICAgICAgY2xhc3M9XCJoLTQgdy00IG1sLWF1dG9cIlxuICAgICAgICAgICAgICAgICAgZmlsbD1cIm5vbmVcIlxuICAgICAgICAgICAgICAgICAgdmlld0JveD1cIjAgMCAyNCAyNFwiXG4gICAgICAgICAgICAgICAgICBzdHJva2U9XCJjdXJyZW50Q29sb3JcIlxuICAgICAgICAgICAgICAgID5cbiAgICAgICAgICAgICAgICAgIDxwYXRoIHN0cm9rZS1saW5lY2FwPVwicm91bmRcIiBzdHJva2UtbGluZWpvaW49XCJyb3VuZFwiIHN0cm9rZS13aWR0aD1cIjJcIiBkPVwiTTUgMTNsNCA0TDE5IDdcIiAvPlxuICAgICAgICAgICAgICAgIDwvc3ZnPlxuICAgICAgICAgICAgICB7L2lmfVxuICAgICAgICAgICAgPC9idXR0b24+XG4gICAgICAgICAgPC9saT5cbiAgICAgICAgey9lYWNofVxuICAgICAgPC91bD5cbiAgICA8L2Rpdj5cbiAgey9pZn1cbjwvZGl2PlxuXG48c3R5bGU+XG4gIC50aGVtZS1zZWxlY3RvciB7XG4gICAgdXNlci1zZWxlY3Q6IG5vbmU7XG4gIH1cbjwvc3R5bGU+XG4iXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQWlHQSxFQUFFLDZCQUFlLENBQUM7QUFDbEIsSUFBSSxpQkFBaUI7QUFDckIiLCJpZ25vcmVMaXN0IjpbXX0= */"
};
function ThemeSelector($$renderer, $$props) {
  $$renderer.global.css.add($$css);
  $$renderer.component(
    ($$renderer2) => {
      const themes = [
        { value: "dark", label: "Dark", icon: "\u{1F319}" },
        { value: "dracula", label: "Dracula", icon: "\u{1F9DB}" },
        { value: "synthwave", label: "Synthwave", icon: "\u{1F306}" },
        { value: "business", label: "Business", icon: "\u{1F4BC}" },
        { value: "dim", label: "Dim", icon: "\u{1F311}" }
      ];
      let currentTheme = "dark";
      let isOpen = false;
      function applyTheme(theme) {
        currentTheme = theme;
        document.documentElement.setAttribute("data-theme", theme);
        localStorage.setItem("theme", theme);
      }
      function selectTheme(theme) {
        applyTheme(theme);
        isOpen = false;
      }
      function toggleDropdown() {
        isOpen = !isOpen;
      }
      function handleClickOutside(event2) {
        if (!event2.target.closest(".theme-selector")) {
          isOpen = false;
        }
      }
      noop(() => {
        const savedTheme = localStorage.getItem("theme") || "dark";
        applyTheme(savedTheme);
        document.addEventListener("click", handleClickOutside);
        return () => document.removeEventListener("click", handleClickOutside);
      });
      $$renderer2.push(`<div class="theme-selector relative svelte-k618ps">`);
      push_element($$renderer2, "div", 48, 0);
      $$renderer2.push(`<button class="btn btn-ghost btn-sm gap-2" aria-label="Select theme">`);
      push_element($$renderer2, "button", 49, 2);
      $$renderer2.push(`<span class="text-lg">`);
      push_element($$renderer2, "span", 54, 4);
      $$renderer2.push(`${escape_html(themes.find((t) => t.value === currentTheme)?.icon || "\u{1F319}")}</span>`);
      pop_element();
      $$renderer2.push(` <span class="hidden md:inline">`);
      push_element($$renderer2, "span", 55, 4);
      $$renderer2.push(`Theme</span>`);
      pop_element();
      $$renderer2.push(` <svg xmlns="http://www.w3.org/2000/svg"${attr_class(`h-4 w-4 transition-transform ${stringify(isOpen ? "rotate-180" : "")}`)} fill="none" viewBox="0 0 24 24" stroke="currentColor">`);
      push_element($$renderer2, "svg", 56, 4);
      $$renderer2.push(`<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7">`);
      push_element($$renderer2, "path", 63, 6);
      $$renderer2.push(`</path>`);
      pop_element();
      $$renderer2.push(`</svg>`);
      pop_element();
      $$renderer2.push(`</button>`);
      pop_element();
      $$renderer2.push(` `);
      if (isOpen) {
        $$renderer2.push("<!--[-->");
        $$renderer2.push(`<div class="absolute right-0 mt-2 w-48 bg-base-200 rounded-lg shadow-xl border border-base-300 z-50">`);
        push_element($$renderer2, "div", 68, 4);
        $$renderer2.push(`<ul class="menu p-2">`);
        push_element($$renderer2, "ul", 69, 6);
        $$renderer2.push(`<!--[-->`);
        const each_array = ensure_array_like(themes);
        for (let $$index = 0, $$length = each_array.length; $$index < $$length; $$index++) {
          let theme = each_array[$$index];
          $$renderer2.push(`<li>`);
          push_element($$renderer2, "li", 71, 10);
          $$renderer2.push(`<button${attr_class(`flex items-center gap-3 ${stringify(currentTheme === theme.value ? "active bg-primary text-primary-content" : "")}`)}>`);
          push_element($$renderer2, "button", 72, 12);
          $$renderer2.push(`<span class="text-lg">`);
          push_element($$renderer2, "span", 76, 14);
          $$renderer2.push(`${escape_html(theme.icon)}</span>`);
          pop_element();
          $$renderer2.push(` <span>`);
          push_element($$renderer2, "span", 77, 14);
          $$renderer2.push(`${escape_html(theme.label)}</span>`);
          pop_element();
          $$renderer2.push(` `);
          if (currentTheme === theme.value) {
            $$renderer2.push("<!--[-->");
            $$renderer2.push(`<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">`);
            push_element($$renderer2, "svg", 79, 16);
            $$renderer2.push(`<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7">`);
            push_element($$renderer2, "path", 86, 18);
            $$renderer2.push(`</path>`);
            pop_element();
            $$renderer2.push(`</svg>`);
            pop_element();
          } else {
            $$renderer2.push("<!--[!-->");
          }
          $$renderer2.push(`<!--]--></button>`);
          pop_element();
          $$renderer2.push(`</li>`);
          pop_element();
        }
        $$renderer2.push(`<!--]--></ul>`);
        pop_element();
        $$renderer2.push(`</div>`);
        pop_element();
      } else {
        $$renderer2.push("<!--[!-->");
      }
      $$renderer2.push(`<!--]--></div>`);
      pop_element();
    },
    ThemeSelector
  );
}
ThemeSelector.render = function() {
  throw new Error("Component.render(...) is no longer valid in Svelte 5. See https://svelte.dev/docs/svelte/v5-migration-guide#Components-are-no-longer-classes for more information");
};
var ThemeSelector_default = ThemeSelector;

// svelte/Navbar.svelte
Navbar[FILENAME] = "svelte/Navbar.svelte";
function Navbar($$renderer, $$props) {
  $$renderer.component(
    ($$renderer2) => {
      let currentPage = fallback($$props["currentPage"], "");
      let isScrolled = false;
      let isMenuOpen = false;
      let dropdownRef;
      function handleScroll() {
        isScrolled = window.scrollY > 20;
      }
      function toggleMenu() {
        isMenuOpen = !isMenuOpen;
      }
      function closeMenu() {
        isMenuOpen = false;
      }
      function handleClickOutside(event2) {
        if (dropdownRef && !dropdownRef.contains(event2.target)) {
          closeMenu();
        }
      }
      noop(() => {
        handleScroll();
        window.addEventListener("scroll", handleScroll);
        document.addEventListener("click", handleClickOutside);
      });
      onDestroy(() => {
        window.removeEventListener("scroll", handleScroll);
        document.removeEventListener("click", handleClickOutside);
      });
      $$renderer2.push(`<div${attr_class(`navbar fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${isScrolled ? "bg-base-100/80 backdrop-blur-md border-b border-base-300" : "bg-transparent"}`)}>`);
      push_element($$renderer2, "div", 41, 0);
      $$renderer2.push(`<div class="navbar-start">`);
      push_element($$renderer2, "div", 46, 2);
      $$renderer2.push(`<div${attr_class("dropdown lg:hidden", void 0, { "dropdown-open": isMenuOpen })}>`);
      push_element($$renderer2, "div", 48, 4);
      $$renderer2.push(`<button aria-label="Toggle navigation menu"${attr("aria-expanded", isMenuOpen)} aria-controls="mobile-nav" class="btn btn-ghost">`);
      push_element($$renderer2, "button", 49, 6);
      $$renderer2.push(`<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">`);
      push_element($$renderer2, "svg", 56, 8);
      $$renderer2.push(`<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16">`);
      push_element($$renderer2, "path", 57, 10);
      $$renderer2.push(`</path>`);
      pop_element();
      $$renderer2.push(`</svg>`);
      pop_element();
      $$renderer2.push(`</button>`);
      pop_element();
      $$renderer2.push(` `);
      if (isMenuOpen) {
        $$renderer2.push("<!--[-->");
        $$renderer2.push(`<ul id="mobile-nav" class="menu menu-sm dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-52 p-2 shadow">`);
        push_element($$renderer2, "ul", 61, 8);
        $$renderer2.push(`<li>`);
        push_element($$renderer2, "li", 62, 10);
        $$renderer2.push(`<a href="/"${attr_class("", void 0, { "active": currentPage === "home" })}>`);
        push_element($$renderer2, "a", 62, 14);
        $$renderer2.push(`Home</a>`);
        pop_element();
        $$renderer2.push(`</li>`);
        pop_element();
        $$renderer2.push(` <li>`);
        push_element($$renderer2, "li", 63, 10);
        $$renderer2.push(`<a href="/references?category=coding">`);
        push_element($$renderer2, "a", 63, 14);
        $$renderer2.push(`Coding</a>`);
        pop_element();
        $$renderer2.push(`</li>`);
        pop_element();
        $$renderer2.push(` <li>`);
        push_element($$renderer2, "li", 64, 10);
        $$renderer2.push(`<a href="/references?category=ai">`);
        push_element($$renderer2, "a", 64, 14);
        $$renderer2.push(`AI</a>`);
        pop_element();
        $$renderer2.push(`</li>`);
        pop_element();
        $$renderer2.push(` <li>`);
        push_element($$renderer2, "li", 65, 10);
        $$renderer2.push(`<a href="/references?category=n8n">`);
        push_element($$renderer2, "a", 65, 14);
        $$renderer2.push(`n8n</a>`);
        pop_element();
        $$renderer2.push(`</li>`);
        pop_element();
        $$renderer2.push(` <li>`);
        push_element($$renderer2, "li", 66, 10);
        $$renderer2.push(`<a href="/references?category=tools">`);
        push_element($$renderer2, "a", 66, 14);
        $$renderer2.push(`Tools</a>`);
        pop_element();
        $$renderer2.push(`</li>`);
        pop_element();
        $$renderer2.push(` <li>`);
        push_element($$renderer2, "li", 67, 10);
        $$renderer2.push(`<a href="/references"${attr_class("", void 0, { "active": currentPage === "references" })}>`);
        push_element($$renderer2, "a", 67, 14);
        $$renderer2.push(`Prompts</a>`);
        pop_element();
        $$renderer2.push(`</li>`);
        pop_element();
        $$renderer2.push(`</ul>`);
        pop_element();
      } else {
        $$renderer2.push("<!--[!-->");
      }
      $$renderer2.push(`<!--]--></div>`);
      pop_element();
      $$renderer2.push(` <a href="/" class="btn btn-ghost text-xl font-semibold tracking-tight">`);
      push_element($$renderer2, "a", 73, 4);
      $$renderer2.push(`UrielM<span class="text-base-content/50">`);
      push_element($$renderer2, "span", 74, 12);
      $$renderer2.push(`.dev</span>`);
      pop_element();
      $$renderer2.push(`</a>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(` <div class="navbar-center hidden lg:flex">`);
      push_element($$renderer2, "div", 79, 2);
      $$renderer2.push(`<div class="flex items-center gap-8">`);
      push_element($$renderer2, "div", 80, 4);
      $$renderer2.push(`<a href="/"${attr_class(`font-medium transition-colors ${currentPage === "home" ? "text-primary font-bold" : "text-base-content hover:text-primary"}`)}>`);
      push_element($$renderer2, "a", 81, 6);
      $$renderer2.push(`Home</a>`);
      pop_element();
      $$renderer2.push(` <a href="/references?category=coding" class="font-medium text-base-content hover:text-primary transition-colors">`);
      push_element($$renderer2, "a", 87, 6);
      $$renderer2.push(`Coding</a>`);
      pop_element();
      $$renderer2.push(` <a href="/references?category=ai" class="font-medium text-base-content hover:text-primary transition-colors">`);
      push_element($$renderer2, "a", 93, 6);
      $$renderer2.push(`AI</a>`);
      pop_element();
      $$renderer2.push(` <a href="/references?category=n8n" class="font-medium text-base-content hover:text-primary transition-colors">`);
      push_element($$renderer2, "a", 99, 6);
      $$renderer2.push(`n8n</a>`);
      pop_element();
      $$renderer2.push(` <a href="/references?category=tools" class="font-medium text-base-content hover:text-primary transition-colors">`);
      push_element($$renderer2, "a", 105, 6);
      $$renderer2.push(`Tools</a>`);
      pop_element();
      $$renderer2.push(` <a href="/references"${attr_class(`font-medium transition-colors ${currentPage === "references" ? "text-primary font-bold" : "text-base-content hover:text-primary"}`)}>`);
      push_element($$renderer2, "a", 111, 6);
      $$renderer2.push(`Prompts</a>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(` <div class="navbar-end gap-2">`);
      push_element($$renderer2, "div", 121, 2);
      ThemeSelector_default($$renderer2, {});
      $$renderer2.push(`<!----> <a href="mailto:hello@urielm.dev" class="btn btn-sm bg-black dark:bg-white text-white dark:text-black hover:bg-gray-800 dark:hover:bg-gray-200 border-0 rounded-full px-6">`);
      push_element($$renderer2, "a", 123, 4);
      $$renderer2.push(`Get in Touch</a>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      bind_props($$props, { currentPage });
    },
    Navbar
  );
}
Navbar.render = function() {
  throw new Error("Component.render(...) is no longer valid in Svelte 5. See https://svelte.dev/docs/svelte/v5-migration-guide#Components-are-no-longer-classes for more information");
};
var Navbar_default = Navbar;

// svelte/SubNav.svelte
var SubNav_exports = {};
__export(SubNav_exports, {
  default: () => SubNav_default
});
init_server();
SubNav[FILENAME] = "svelte/SubNav.svelte";
function SubNav($$renderer, $$props) {
  $$renderer.component(
    ($$renderer2) => {
      let activeFilter = fallback($$props["activeFilter"], "all");
      let categories = fallback($$props["categories"], () => [], true);
      let live = $$props["live"];
      function selectFilter(filter) {
        live.pushEvent("filter_changed", { category: filter });
      }
      $$renderer2.push(`<div class="border-b border-gray-200 dark:border-white/10 bg-white dark:bg-[#0f0f0f]">`);
      push_element($$renderer2, "div", 11, 0);
      $$renderer2.push(`<div class="container mx-auto px-4">`);
      push_element($$renderer2, "div", 12, 2);
      $$renderer2.push(`<nav class="flex gap-6 overflow-x-auto scrollbar-hide" aria-label="Reference filters">`);
      push_element($$renderer2, "nav", 13, 4);
      $$renderer2.push(`<button${attr_class(`py-3 px-1 border-b-2 font-medium text-sm transition-colors whitespace-nowrap ${activeFilter === "all" ? "border-purple-600 text-purple-600 dark:text-purple-400" : "border-transparent text-gray-600 dark:text-white/60 hover:text-gray-900 dark:hover:text-white hover:border-gray-300 dark:hover:border-white/30"}`)}>`);
      push_element($$renderer2, "button", 14, 6);
      $$renderer2.push(`All</button>`);
      pop_element();
      $$renderer2.push(` <!--[-->`);
      const each_array = ensure_array_like(categories);
      for (let $$index = 0, $$length = each_array.length; $$index < $$length; $$index++) {
        let category = each_array[$$index];
        $$renderer2.push(`<button${attr_class(`py-3 px-1 border-b-2 font-medium text-sm transition-colors whitespace-nowrap capitalize ${activeFilter === category ? "border-purple-600 text-purple-600 dark:text-purple-400" : "border-transparent text-gray-600 dark:text-white/60 hover:text-gray-900 dark:hover:text-white hover:border-gray-300 dark:hover:border-white/30"}`)}>`);
        push_element($$renderer2, "button", 25, 8);
        $$renderer2.push(`${escape_html(category)}</button>`);
        pop_element();
      }
      $$renderer2.push(`<!--]--></nav>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      bind_props($$props, { activeFilter, categories, live });
    },
    SubNav
  );
}
SubNav.render = function() {
  throw new Error("Component.render(...) is no longer valid in Svelte 5. See https://svelte.dev/docs/svelte/v5-migration-guide#Components-are-no-longer-classes for more information");
};
var SubNav_default = SubNav;

// svelte/ThemeToggle.svelte
var ThemeToggle_exports = {};
__export(ThemeToggle_exports, {
  default: () => ThemeToggle_default
});
init_server();
init_index_server();
ThemeToggle[FILENAME] = "svelte/ThemeToggle.svelte";
function ThemeToggle($$renderer, $$props) {
  $$renderer.component(
    ($$renderer2) => {
      let currentTheme = "light";
      function toggleTheme() {
        const newTheme = currentTheme === "light" ? "dark" : "light";
        currentTheme = newTheme;
        document.documentElement.setAttribute("data-theme", newTheme);
        localStorage.setItem("phx:theme", newTheme);
        window.dispatchEvent(new CustomEvent("phx:set-theme", { detail: { theme: newTheme } }));
      }
      noop(() => {
        const stored = localStorage.getItem("phx:theme");
        const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
        currentTheme = stored || (prefersDark ? "dark" : "light");
        if (!document.documentElement.hasAttribute("data-theme")) {
          document.documentElement.setAttribute("data-theme", currentTheme);
        }
      });
      $$renderer2.push(`<button class="relative w-8 h-8 rounded-full flex items-center justify-center hover:bg-base-200 transition-colors" aria-label="Toggle theme">`);
      push_element($$renderer2, "button", 30, 0);
      if (currentTheme === "light") {
        $$renderer2.push("<!--[-->");
        $$renderer2.push(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">`);
        push_element($$renderer2, "svg", 37, 4);
        $$renderer2.push(`<path fill-rule="evenodd" d="M7.455 2.004a.75.75 0 01.26.77 7 7 0 009.958 7.967.75.75 0 011.067.853A8.5 8.5 0 116.647 1.921a.75.75 0 01.808.083z" clip-rule="evenodd">`);
        push_element($$renderer2, "path", 38, 6);
        $$renderer2.push(`</path>`);
        pop_element();
        $$renderer2.push(`</svg>`);
        pop_element();
      } else {
        $$renderer2.push("<!--[!-->");
        $$renderer2.push(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">`);
        push_element($$renderer2, "svg", 42, 4);
        $$renderer2.push(`<path d="M10 2a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 2zM10 15a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 15zM10 7a3 3 0 100 6 3 3 0 000-6zM15.657 5.404a.75.75 0 10-1.06-1.06l-1.061 1.06a.75.75 0 001.06 1.06l1.06-1.06zM6.464 14.596a.75.75 0 10-1.06-1.06l-1.06 1.06a.75.75 0 001.06 1.06l1.06-1.06zM18 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 0118 10zM5 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 015 10zM14.596 15.657a.75.75 0 001.06-1.06l-1.06-1.061a.75.75 0 10-1.06 1.06l1.06 1.06zM5.404 6.464a.75.75 0 001.06-1.06l-1.06-1.06a.75.75 0 10-1.061 1.06l1.06 1.06z">`);
        push_element($$renderer2, "path", 43, 6);
        $$renderer2.push(`</path>`);
        pop_element();
        $$renderer2.push(`</svg>`);
        pop_element();
      }
      $$renderer2.push(`<!--]--></button>`);
      pop_element();
    },
    ThemeToggle
  );
}
ThemeToggle.render = function() {
  throw new Error("Component.render(...) is no longer valid in Svelte 5. See https://svelte.dev/docs/svelte/v5-migration-guide#Components-are-no-longer-classes for more information");
};
var ThemeToggle_default = ThemeToggle;

// svelte/WorkflowStatusCard.svelte
var WorkflowStatusCard_exports = {};
__export(WorkflowStatusCard_exports, {
  default: () => WorkflowStatusCard_default
});
init_server();
WorkflowStatusCard[FILENAME] = "svelte/WorkflowStatusCard.svelte";
function WorkflowStatusCard($$renderer, $$props) {
  $$renderer.component(
    ($$renderer2) => {
      let delay = fallback($$props["delay"], 0);
      $$renderer2.push(`<div class="absolute hidden lg:block bottom-20 right-10 xl:right-32 w-auto bg-base-100/40 backdrop-blur-xl border border-base-300/50 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.1)] rounded-2xl p-4 animate-float rotate-[3deg]"${attr_style(`animation-delay: ${stringify(delay)}s`)}>`);
      push_element($$renderer2, "div", 5, 0);
      $$renderer2.push(`<div class="flex items-center space-x-3 pr-2">`);
      push_element($$renderer2, "div", 9, 2);
      $$renderer2.push(`<div class="w-10 h-10 rounded-xl bg-[#EA4B71] flex items-center justify-center text-white shadow-lg shadow-pink-500/20">`);
      push_element($$renderer2, "div", 10, 4);
      $$renderer2.push(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">`);
      push_element($$renderer2, "svg", 11, 6);
      $$renderer2.push(`<path fill-rule="evenodd" d="M15.312 11.424a5.5 5.5 0 01-9.201 2.466l-.312-.311h2.433a.75.75 0 000-1.5H3.989a.75.75 0 00-.75.75v4.242a.75.75 0 001.5 0v-2.43l.31.31a7 7 0 0011.712-3.138.75.75 0 00-1.449-.39zm1.23-3.723a.75.75 0 00.219-.53V2.929a.75.75 0 00-1.5 0V5.36l-.31-.31A7 7 0 003.239 8.188a.75.75 0 101.448.389A5.5 5.5 0 0113.89 6.11l.311.31h-2.432a.75.75 0 000 1.5h4.243a.75.75 0 00.53-.219z" clip-rule="evenodd">`);
      push_element($$renderer2, "path", 12, 8);
      $$renderer2.push(`</path>`);
      pop_element();
      $$renderer2.push(`</svg>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(` <div class="text-left">`);
      push_element($$renderer2, "div", 15, 4);
      $$renderer2.push(`<div class="text-xs text-base-content/60 font-medium">`);
      push_element($$renderer2, "div", 16, 6);
      $$renderer2.push(`Active Workflow</div>`);
      pop_element();
      $$renderer2.push(` <div class="text-sm font-bold text-base-content">`);
      push_element($$renderer2, "div", 17, 6);
      $$renderer2.push(`Lead Gen Bot \xB7 Running</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      $$renderer2.push(`</div>`);
      pop_element();
      bind_props($$props, { delay });
    },
    WorkflowStatusCard
  );
}
WorkflowStatusCard.render = function() {
  throw new Error("Component.render(...) is no longer valid in Svelte 5. See https://svelte.dev/docs/svelte/v5-migration-guide#Components-are-no-longer-classes for more information");
};
var WorkflowStatusCard_default = WorkflowStatusCard;

// import-glob:../svelte/**/*.svelte
var modules = [CodeSnippetCard_exports, Counter_exports, Navbar_exports, SubNav_exports, ThemeSelector_exports, ThemeToggle_exports, WorkflowStatusCard_exports];
var __default = modules;
var filenames = ["../svelte/CodeSnippetCard.svelte", "../svelte/Counter.svelte", "../svelte/Navbar.svelte", "../svelte/SubNav.svelte", "../svelte/ThemeSelector.svelte", "../svelte/ThemeToggle.svelte", "../svelte/WorkflowStatusCard.svelte"];

// js/server.js
var import_live_svelte = __toESM(require_live_svelte_cjs());
var render2 = (0, import_live_svelte.getRender)(__exports);
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  render
});
