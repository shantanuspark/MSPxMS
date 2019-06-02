$(document).ready(function () {
    $(".progress").hide();
    $("#analyze-btn").click(function () {
        $('#analyze-btn').addClass('disabled');
        $('#results').html("");
        document.getElementById('download-results').innerHTML = '';
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
        contextMenu: ['remove_row', 'alignment'],
        exportFile: true,
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
          '0015',
          '0060',
          '0240',
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
      
      document.getElementById('download-results').innerHTML = `
      <br />
        <div class="row">
            <div class="mx-auto">
                <a class="btn btn-secondary" href="#" id="export-csv" role="button" style="width: 200px;">Export to a .csv file</a>
            </div>
        </div>
      <br />
      `

      document.getElementById("export-csv").addEventListener("click", function(event) { hot.getPlugin("exportFile").downloadFile("csv", {filename: "MSPxMS"});})

}


$('#inputGroupFile01').on('change', function () {
    var fileName = $(this).val();
    $(this).next('.custom-file-label').html(fileName);
})
$('#inputGroupFile02').on('change', function () {
    var fileName = $(this).val();
    $(this).next('.custom-file-label').html(fileName);
})