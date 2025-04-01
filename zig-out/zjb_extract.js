const Zjb = class {
  new_handle(value) {
    if (value === null) {
      return 0;
    }
    const result = this._next_handle;
    this._handles.set(result, value);
    this._next_handle++;
    return result;
  }
  dataView() {
    if (this._cached_data_view.buffer.byteLength !== this.instance.exports.memory.buffer.byteLength) {
      this._cached_data_view = new DataView(this.instance.exports.memory.buffer);
    }
    return this._cached_data_view;
  }
  constructor() {
    this._decoder = new TextDecoder();
    this.imports = {
      "call_o_o_createElement": (arg0, id) => {
        return this.new_handle(this._handles.get(id).createElement(this._handles.get(arg0)));
      },
      "call_o_o_getElementById": (arg0, id) => {
        return this.new_handle(this._handles.get(id).getElementById(this._handles.get(arg0)));
      },
      "call_o_v_appendChild": (arg0, id) => {
        this._handles.get(id).appendChild(this._handles.get(arg0));
      },
      "call_oo_v_addEventListener": (arg0, arg1, id) => {
        this._handles.get(id).addEventListener(this._handles.get(arg0), this._handles.get(arg1));
      },
      "call_oo_v_error": (arg0, arg1, id) => {
        this._handles.get(id).error(this._handles.get(arg0), this._handles.get(arg1));
      },
      "get_o_body": (id) => {
        return this.new_handle(this._handles.get(id).body);
      },
      "get_o_console": (id) => {
        return this.new_handle(this._handles.get(id).console);
      },
      "get_o_document": (id) => {
        return this.new_handle(this._handles.get(id).document);
      },
      "get_o_handleCounterClick": (id) => {
        return this.new_handle(this._handles.get(id).handleCounterClick);
      },
      "handleCount": () => {
        return this._handles.size;
      },
      "release": (id) => {
        this._handles.delete(id);
      },
      "set_o_id": (arg0, id) => {
        this._handles.get(id).id = this._handles.get(arg0);
      },
      "set_o_textContent": (arg0, id) => {
        this._handles.get(id).textContent = this._handles.get(arg0);
      },
      "string": (ptr, len) => {
        return this.new_handle(this._decoder.decode(new Uint8Array(this.instance.exports.memory.buffer, ptr, len)));
      },
      "throwAndRelease": (id) => {
        var message = this._handles.get(id);
        this._handles.delete(id);
        throw message;
      },
    };
    this.exports = {
      "checkTestVar": () => {
        return this.instance.exports.zjb_fn__f32_checkTestVar();
      },
      "setTestVar": () => {
        return this.instance.exports.zjb_fn__f32_setTestVar();
      },
      "handleCounterClick": () => {
        this.instance.exports.zjb_fn__v_handleCounterClick();
      },
      "incrementAndGet": (arg0) => {
        return this.instance.exports.zjb_fn_i32_i32_incrementAndGet(arg0);
      },
    };
    this.instance = null;
    this._cached_data_view = null;
    this._export_reverse_handles = {};
    this._handles = new Map();
    this._handles.set(0, null);
    this._handles.set(1, window);
    this._handles.set(2, "");
    this._handles.set(3, this.exports);
    this._next_handle = 4;
  }
  setInstance(instance) {
    this.instance = instance;
    const initialView = new DataView(instance.exports.memory.buffer);
    this._cached_data_view = initialView;
    {
      const ptr = instance.exports.zjb_global_f32_test_var.value;
      Object.defineProperty(this.exports, "test_var", {
        get: () => this.dataView().getFloat32(ptr, true),
        set: v => this.dataView().setFloat32(ptr, v, true),
        enumerable: true,
      });
    }
  }
};
