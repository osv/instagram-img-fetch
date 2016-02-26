<my-app>
  <h1>Instagram images</h1>
  <div class="row">
    <div class="col-md-12">
      Last image was: <span class="label label-info">{ lastUpdated }</span>,
      <span if={ !loading }>
        Total images: <span class="label label-info">{ data.urls.length }</span>
      </span>
    </div>
  </div>
  <hr/>
  <my-table if={!loading} table-data={data}></my-table>

  <script>
   var vm = this;
   vm.data = null;
   vm.loading = true;
   vm.lastUpdated = 'Fetching data...';

   loadJSON('maria.json', function(data) {
     vm.loading = false;
     vm.data = data;
     vm.lastUpdated = moment(data.lastUpdate).fromNow();
     vm.update();
   });

   function loadJSON(url, cb) {

     var xobj = new XMLHttpRequest();
     xobj.overrideMimeType("application/json");
     xobj.open('GET', url, true);
     xobj.onreadystatechange = function () {
       if (xobj.readyState == 4 && xobj.status == "200") {
         cb(JSON.parse(xobj.responseText));
       }
     };
     xobj.send(null);
   }
  </script>
</my-app>
