function autocomplete_search(url, set_extra) {
  let that = this;
  return function( request, response ) {
    if ( that.xhr ) {
      that.xhr.abort();
    }
    if (set_extra) {
      set_extra(request)
    }

    that.xhr = $.ajax( {
      url: url,
      data: request,
      dataType: "json",
      success: function( data ) {
        response( data );
      },
      error: function() {
        response( [] );
      }
    } );
  }
}