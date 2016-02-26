<!-- select page size
     <current> - current selected,
     on-select - callback on select new page size -->
<my-per-page-select>
  <select class="form-control" onChange={ selectPerPage }>
    <option each={ size in sizes } selected={ parent.opts.current == size }>{size}</option>
  </select>
  <script>
   var vm = this;
   vm.sizes = [3, 6, 12, 18, 30, 60, 90, 130];

   vm.selectPerPage = function(e) {
     var cb = vm.opts.onSelect;

     if (cb) {
       cb(e.target.value);
     }
   }
  </script>
  <style scoped>
    select {
      margin: 20px 0;
    }
  </style>
</my-per-page-select>
