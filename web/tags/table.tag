<my-table>
  <div class="row">
    <div class="col-sm-12">
      <input class="form-control" placeholder="Search for..." onKeyUp={ queryChange }/>
    </div>
  </div>
  <div class="row">
    <div class="col-sm-12">
      <my-pagination current={ page } pages={ totalPages } />
      <div class="pull-right">
        Per page: <my-per-page-select current={ perPage } on-select={ changePerPage }></my-per-page-select>
      </div>
    </div>
  </div>
  <div class="row">
    <div class="col-sm-6 col-md-4" each={ itemsToDisplay }>
      <div class="thumbnail hideoverflow">
        <div>
          <a href={ l } target="_blank" title="Go to instagram">
            <img class="img-thumbnail img-responsive"
                 src={ l }>
          </a>
        </div>
        <div class="time pull-right">
          <my-from-now date={ time }></my-from-now>
          <span><a target="_blank" title="Direct link to instagram image" href="{ inst }">img</a></span>
        </div>
        <div class="caption">{ title }</div>
      </div>
    </div>
  </div>
  <script>
    var LS_PER_PAGE = 'perPage';

    var vm = this;

    vm.page = 1;
    vm.perPage = getPerPage();

    updatePaginator();

    riot.route(function(page) {
      console.log('route', page)
      vm.page = +page;
      vm.perPage = getPerPage();
      vm.update();
    });

    vm.on('update', function() {
      if (vm.opts.tableData && vm.opts.tableData.urls) {
        var re = new RegExp(vm.queryText, 'i');
        var allItems = vm.opts.tableData.urls || [];
        vm.items = [];
        allItems.forEach(function filter(item) {
          if (re.test(item.title)) {
            vm.items.push(item);
          }
        })
      }
      updatePaginator();
    });

    vm.changePerPage = function(perPage) {
      vm.perPage = perPage;
      localStorage.setItem(LS_PER_PAGE, perPage);
      riot.route('/1'); /* goto first page */
      vm.update(); /* need, because if you are in page 1 - than no route will be called  */
    };

    vm.queryChange = function(e) {
      vm.queryText = e.target.value;
      riot.route('/1');
    };

    function getPerPage() {
      return +localStorage.getItem(LS_PER_PAGE) || 12;
    }

    function updatePaginator() {
      var items = vm.items || [],
          page = (vm.page || 1) -1,
          perPage = vm.perPage,
          offset = page * perPage;
      vm.totalPages = (items.length / perPage) | 0;/* as integer */
      vm.itemsToDisplay = items.slice(offset, offset + perPage);
      vm.update();
    }
  </script>

  <style scoped>
    .caption {
      line-height: 1em;
      height: 9em;
    }
    .time {
      line-height: 1em;
      color: #aaa;
    }
    .hideoverflow {
      overflow: hidden;
    }
  </style>
</my-table>

<!-- convert 'date' to str from now -->
<my-from-now>
  <span>{date}</span>
  <script>
    this.date = moment(opts.date).fromNow()
  </script>
</my-from-now>
