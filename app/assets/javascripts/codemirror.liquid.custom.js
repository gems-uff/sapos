CodeMirror.defineMode("liquid", function(config) {
  const htmlBase = CodeMirror.getMode(config, "htmlmixed");

  return CodeMirror.overlayMode(htmlBase, {
    token: function(stream) {
      if (stream.match("{{")) {
        while ((ch = stream.next()) != null)
          if (ch === "}" && stream.next() === "}") break;
        return "string";
      }
      if (stream.match("{%")) {
        while ((ch = stream.next()) != null)
          if (ch === "%" && stream.next() === "}") break;
        return "tag";
      }
      if (stream.match("{#")) {
        while ((ch = stream.next()) != null)
          if (ch === "#" && stream.next() === "}") break;
        return "comment";
      }
      while (stream.next() != null && !stream.match(/({{|{%|{#)/, false)) {}
      return null;
    }
  });
});