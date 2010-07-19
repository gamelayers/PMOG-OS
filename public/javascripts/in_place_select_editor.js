Ajax.InPlaceSelectEditor = Class.create(); //<label id="code.create" />
Object.extend(Object.extend(Ajax.InPlaceSelectEditor.prototype,
                            Ajax.InPlaceEditor.prototype), {
    createEditField: function() {
      var text;
      if(this.options.loadTextURL) { //<label id="code.get_text" />
        text = this.options.loadingText;
      } else {
        text = this.getText();
      }
      this.options.textarea = false;
      var selectField = document.createElement("select"); //<label id="code.select" />
      selectField.name = "value";
      selectField.innerHTML=this.options.selectOptionsHTML ||//<label id="code.select_options" />
                     "<option>" + text + "</option>"; 
      $A(selectField.options).each(function(opt, index){//<label id="code.selected_loop" />
        if(text == opt.value) {
          selectField.selectedIndex = index;
        } 
      }
      );
      selectField.style.backgroundColor = this.options.highlightcolor;
      this._controls.editor = selectField;
      if(this.options.loadTextURL) {
        this.loadExternalText();
      }
      this._form.appendChild(this._controls.editor);
    }
});