$(document).ready(function () {
    $(".progress").hide();
    $("#analyze-btn").click(function () {
        $('#analyze-btn').addClass('disabled');
        $('#results').html("");
        document.getElementById('download-results').innerHTML = '';
        document.getElementById('results-info').innerHTML = '';
        $('.progress-bar').css('width', '25%');
        $('.progress-bar').html('Uploading the long file');
        $(".progress").show();

        var fd = new FormData($("#fileinfo")[0]);

        $.ajax({
            url: '/upload-long-file',
            type: 'POST',
            data: fd,
            processData: false,
            contentType: false,
            success: function (data) {
                longFileName = data
                $('.progress-bar').html('Uploading short file');
                $('.progress-bar').css('width', '45%');
                $.ajax({
                    url: '/upload-short-file',
                    type: 'POST',
                    data: fd,
                    processData: false,
                    contentType: false,
                    success: function (data) {
                        shortFileName = data
                        console.log(longFileName,shortFileName)
                        $('.progress-bar').html('Analyzing..');
                        $('.progress-bar').css('width', '75%');
                        $.ajax({
                            url: '/execute/'+longFileName+'/'+shortFileName,
                            type: 'POST',
                            data: fd,
                            processData: false,
                            contentType: false,
                            success: function (data) {
                                outputFileName = data.split('.')[0]
                                $('.progress-bar').html('Visualizing Results');
                                $('.progress-bar').css('width', '95%');
                                $.ajax({
                                    url: '/get_content/'+outputFileName,
                                    type: 'GET',
                                    success: function (data) {
                                        displayResult(data)
                                        $.ajax({
                                            url: '/clean/'+longFileName+'/'+shortFileName+'/'+outputFileName,
                                            type: 'GET'
                                        });
                                    },
                                    error: function (data) {
                                        displayError('Sorry, some unexpected error occured while uploading short file!');
                                    }
                                });
                            },
                            error: function (data) {
                                displayError('Sorry, some unexpected error occured while uploading short file!');
                            }
                        });                        
                    },
                    error: function (data) {
                        displayError('Sorry, some unexpected error occured while uploading short file!');
                    }
                });
            },
            error: function (data) {
                displayError('Sorry, some unexpected error occured while uploading long file!');
            }
        });
    });

});

function displayError(msg) {
    $('#results').html(`
    <div class="alert alert-danger" role="alert">
    `+ msg + `
    </div>
    `);
    $('#analyze-btn').removeClass('disabled');
    $('.progress').hide();
    document.getElementById('download-results').innerHTML = '';
    document.getElementById('results-info').innerHTML = '';
}

function displayResult(data) {
    $("#analyze-btn").removeClass('disabled');
    $('.progress').hide();

    var dataObject = eval(data);

    var hotElement = document.querySelector('#results');
    var hotElementContainer = hotElement.parentNode;
    var width = hotElement.offsetWidth;
    var hotSettings = {
        data: dataObject,
        contextMenu: {
            items: {
                "remove_row" : {},
                "alignment" : {},
                "sequence_logo" : {
                    name: "Create sequence logo",
                    hidden: function () { 
                        if([1, 7, 8, 9].includes(this.getSelectedLast()[1]))
                            return false;
                        return true;
                    },
                    callback: function(key, selection) {
                        setTimeout(function() {
                            createLogo(selection);
                        }, 0);
                    }
                }
            }
        },
        exportFile: true,
        filters: true,
        dropdownMenu: ['alignment',  '---------', 'filter_by_condition', 'filter_action_bar', 'filter_by_value'],
        headerTooltips: true,
        columns: [
            {
            data: 'AccNumber',
            type: 'text',
            width: width/10
            },
            {
            data: 'Sequence Fragment',
            width: width/10
            },
            {
            data: 'Occurrences By Time',
            type: 'text',
            width: width/10
            },
            {
            data: 'Occurances in Experimental NEC',
            type: 'text',
            width: width/10
            },
            {
            data: 'Occurrences in NEC',
            width: width/10
            },
            {
            data: 'Best Experimental Score',
            width: width/10
            },
            {
            data: 'Best NEC Score',
            width: width/10
            },
            {
            data: '0015',
            width: width/10
            },
            {
            data: '0060',
            width: width/10
            },
            {
            data: '0240',
            width: width/10
            }
        ],
        stretchH: 'all',
        autoWrapRow: true,
        rowHeaders: false,
        manualRowResize: true,
        colHeaders: [
          'Accession No.',
          'Sequence Fragment',
          'Occurrences By Time',
          'Occurrences in Experimental NEC',
          'Occurrence in NEC',
          'Best Experimental Score',
          'Best NEC Score',
          '15 mins',
          '60 mins',
          '240 mins',
        ],
        columnSorting: {
            indicator: true
        },
        autoColumnSize: {
            samplingRatio: 1
        },
        licenseKey: 'non-commercial-and-evaluation'
      };
      var hot = new Handsontable(hotElement, hotSettings);

      function createLogo(selection){

        sequences = []
        for(selected in selection){
        for (s of hot.getData(selection[selected]['start']['row'], selection[selected]['start']['col'],
            selection[selected]['end']['row'],selection[selected]['end']['col'])){
                if(s[0]==null)
                    continue
                sequences.push(s[0])
            }
        }
        $('#exampleModal').modal('show')
         
      }
      
      document.getElementById('download-results').innerHTML = `
      <br />
        <div class="row">
            <div class="mx-auto">
                <a class="btn btn-secondary" href="#" id="export-csv" role="button" style="width: 200px;">Export to a .csv file</a>
            </div>
        </div>
      <br />
      `
      document.getElementById('results-info').innerHTML = `
      <div class="alert alert-warning alert-dismissible fade show" role="alert">
            <h6 class="alert-heading">Hint</h6>
            Click on the cloumn name to <strong>sort table</strong> by that column | Right click on any row to
            <strong>remove row</strong> | Select any protein sequence cells and right click to create <strong>sequence logos</strong>
            <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
        </div>
      `

      document.getElementById("export-csv").addEventListener("click", function(event) { hot.getPlugin("exportFile").downloadFile("csv", {filename: "MSPxMS"});})

}

function getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
}

$('#inputGroupFile01').on('change', function () {
    var fileName = $(this).val();
    $(this).next('.custom-file-label').html(fileName);
})

$('#inputGroupFile02').on('change', function () {
    var fileName = $(this).val();
    $(this).next('.custom-file-label').html(fileName);
})

$('#exampleModal').on('show.bs.modal', function (event) {
    
    temp_name = getRandomInt(10000)

    $('#modal-content').html(`
    <div class="text-center">
        <div class="spinner-border" role="status">
            <span class="sr-only">Loading...</span>
        </div>
    </div>
    `);
    
    var modal = $(this)

    $.ajax({
        type: "POST",
        url: '/generate_image/'+temp_name,
        data: JSON.stringify({'sequences':sequences}),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        async: true,
        error: function() {
            console.log('error')
        },
        success: function() {
            var win = window.open(`static/logos/`+temp_name+`.pdf`, '_blank');
            if (win) {
                $('#exampleModal').modal('hide')
                win.focus();
            } else {
                alert('Please allow popups for this website');
            }
        }
      });
     
    modal.find('.modal-title').text('Protein sequence logo')
});