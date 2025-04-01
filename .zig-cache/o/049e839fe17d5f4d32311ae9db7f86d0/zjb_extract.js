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
      "call__f32_now": (id) => {
        return this._handles.get(id).now();
      },
      "call__v_fill": (id) => {
        this._handles.get(id).fill();
      },
      "call_f32_v_log": (arg0, id) => {
        this._handles.get(id).log(arg0);
      },
      "call_f64_v_log": (arg0, id) => {
        this._handles.get(id).log(arg0);
      },
      "call_f64b_f32_getUint16": (arg0, arg1, id) => {
        return this._handles.get(id).getUint16(arg0, Boolean(arg1));
      },
      "call_f64b_f32_getUint32": (arg0, arg1, id) => {
        return this._handles.get(id).getUint32(arg0, Boolean(arg1));
      },
      "call_f64f64_v_lineTo": (arg0, arg1, id) => {
        this._handles.get(id).lineTo(arg0, arg1);
      },
      "call_f64f64_v_moveTo": (arg0, arg1, id) => {
        this._handles.get(id).moveTo(arg0, arg1);
      },
      "call_o_o_getContext": (arg0, id) => {
        return this.new_handle(this._handles.get(id).getContext(this._handles.get(arg0)));
      },
      "call_o_o_getElementById": (arg0, id) => {
        return this.new_handle(this._handles.get(id).getElementById(this._handles.get(arg0)));
      },
      "call_o_v_log": (arg0, id) => {
        this._handles.get(id).log(this._handles.get(arg0));
      },
      "call_oo_v_addEventListener": (arg0, arg1, id) => {
        this._handles.get(id).addEventListener(this._handles.get(arg0), this._handles.get(arg1));
      },
      "call_oo_v_error": (arg0, arg1, id) => {
        this._handles.get(id).error(this._handles.get(arg0), this._handles.get(arg1));
      },
      "call_oo_v_log": (arg0, arg1, id) => {
        this._handles.get(id).log(this._handles.get(arg0), this._handles.get(arg1));
      },
      "dataview": (ptr, len) => {
        return this.new_handle(new DataView(this.instance.exports.memory.buffer, ptr, len));
      },
      "get_f64_length": (id) => {
        return this._handles.get(id).length;
      },
      "get_o_Date": (id) => {
        return this.new_handle(this._handles.get(id).Date);
      },
      "get_o_Map": (id) => {
        return this.new_handle(this._handles.get(id).Map);
      },
      "get_o__handles": (id) => {
        return this.new_handle(this._handles.get(id)._handles);
      },
      "get_o_console": (id) => {
        return this.new_handle(this._handles.get(id).console);
      },
      "get_o_document": (id) => {
        return this.new_handle(this._handles.get(id).document);
      },
      "get_o_keydownCallback": (id) => {
        return this.new_handle(this._handles.get(id).keydownCallback);
      },
      "get_o_zjb": (id) => {
        return this.new_handle(this._handles.get(id).zjb);
      },
      "handleCount": () => {
        return this._handles.size;
      },
      "indexGet_i64_f64": (arg0, id) => {
        return this._handles.get(id)[arg0];
      },
      "indexSet_f64f64": (arg0, arg1, id) => {
        this._handles.get(id)[arg0] = arg1;
      },
      "indexSet_i32f64": (arg0, arg1, id) => {
        this._handles.get(id)[arg0] = arg1;
      },
      "indexSet_i64f64": (arg0, arg1, id) => {
        this._handles.get(id)[arg0] = arg1;
      },
      "indexSet_of64": (arg0, arg1, id) => {
        this._handles.get(id)[this._handles.get(arg0)] = arg1;
      },
      "new__o": (id) => {
        return this.new_handle(new (this._handles.get(id))());
      },
      "release": (id) => {
        this._handles.delete(id);
      },
      "set_f64_Hello": (arg0, id) => {
        this._handles.get(id).Hello = arg0;
      },
      "set_f64_height": (arg0, id) => {
        this._handles.get(id).height = arg0;
      },
      "set_f64_width": (arg0, id) => {
        this._handles.get(id).width = arg0;
      },
      "set_o_fillStyle": (arg0, id) => {
        this._handles.get(id).fillStyle = this._handles.get(arg0);
      },
      "string": (ptr, len) => {
        return this.new_handle(this._decoder.decode(new Uint8Array(this.instance.exports.memory.buffer, ptr, len)));
      },
      "throwAndRelease": (id) => {
        var message = this._handles.get(id);
        this._handles.delete(id);
        throw message;
      },
      "u8ArrayView": (ptr, len) => {
        return this.new_handle(new Uint8Array(this.instance.exports.memory.buffer, ptr, len));
      },
    };
    this.exports = {
      "checkTestVar": () => {
        return this.instance.exports.zjb_fn__f32_checkTestVar();
      },
      "setTestVar": () => {
        return this.instance.exports.zjb_fn__f32_setTestVar();
      },
      "incrementAndGet": (arg0) => {
        return this.instance.exports.zjb_fn_i32_i32_incrementAndGet(arg0);
      },
      "keydownCallback": (arg0) => {
        this.instance.exports.zjb_fn_o_v_keydownCallback(this.new_handle(arg0));
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
