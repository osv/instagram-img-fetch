<!-- build pagination: <current>, <pages> -->
<my-pagination>
  <ul class="pagination">
    <li each={ page in pagination } class={active: isActive(page), disabled: isDots(page) }>
      <span if={ parent.isDots(page) }>{ page }</span>
      <a if={ !parent.isDots(page) } href="#{ page }">{ page }</a>
    </li>
  </ul>

  <script>
   vm = this;

   vm.isActive = function(page) {
     return page === opts.current;
   };

   vm.isDots = function(page) {
     return page === '...';
   };

   vm.on('update', function() {
     var opts = vm.opts,
         current = opts.current,
         pages = opts.pages;
     vm.pagination = mkPagination(current, pages)
   });

   // https://gist.github.com/kottenator/9d936eb3e4e3c3e02598
   // c - current and m - max length
   function mkPagination(c, m) {
     var current = c,
         last = m,
         delta = 3,
         left = current - delta,
         right = current + delta + 1,
         range = [],
         rangeWithDots = [],
         l, i;

     for (i = 1; i <= last; i++) {
       if (i == 1 || i == last || i >= left && i < right) {
         range.push(i);
       }
     }

     range.forEach(function(i) {
       if (l) {
         if (i - l === 2) {
           rangeWithDots.push(l + 1);
         } else if (i - l !== 1) {
           rangeWithDots.push('...');
         }
       }
       rangeWithDots.push(i);
       l = i;

     });

     return rangeWithDots;
   }
  </script>
  <style scoped>
   /* .pagination {margin: 0px 0} */
  </style>

</my-pagination>
