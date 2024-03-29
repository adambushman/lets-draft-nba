function popSources() {

    d3.csv('https://raw.githubusercontent.com/adambushman/basketball-data/master/_data/lets-draft-nba/Current_Industry_Boards.csv', data => {

        let df = aq.from(data)
            .fold(
                aq.not('Rank')
                , {as: ['Source', 'Player']}
            ).objects();

        let section = d3.select('#sources');

        section.selectAll('div')
            .data(d3.map(df, (d) => d.Source).keys().sort())
            .enter()
            .append('div')
            .attr('class', 'form-check')
            .html((d) => {
                let source_trunc = (d).substring(0, (d).indexOf(" ")).toLowerCase();
                let disabled_flag = d.includes('#') ? 'disabled' : '';
                let checked_flag = d.includes('#') ? '' : 'checked';
                console.log(d, disabled_flag)
                return `
                    <input class="form-check-input" type="checkbox" value="${source_trunc}" id="${source_trunc}" ${disabled_flag} ${checked_flag}>
                    <label class="form-check-label sourcename" for="${source_trunc}">${d}</label>
                `
            })
    })
}

function pushSelections(data) {
    let section = d3.select('#draft-players');

    section.selectAll('option').remove();

    section.selectAll('option')
        .data(data)
        .enter()
        .append('option')
        .attr('value', (d,i) => { return i + 1 })
        .text(d => { return d.Player });

    section.insert('option', ':first-child')
        .attr('value', 0)
        .property('selected', true)
        .property('disabled', true)
        .text('Prospect');
}

function getFilters() {
    // Teams to draft for
    let team_options = document.getElementsByClassName("dselect-tag");
    
    // Sources for the rankings
    let sources_options = document.getElementsByClassName("sourcename");
    let sources_labs = Array.from(sources_options).map((d) => { return d.innerText })
    let sources_checked = Array.from(sources_options).map((d) => { return document.getElementById(d.htmlFor).checked })
    let sources_filt = [];
    sources_labs.forEach((d, i) => {
        if(sources_checked[i]) { sources_filt.push(d) }
    });

    // Draft format
    let format_options = document.getElementsByClassName("draft-format");
    let format_labs = Array.from(format_options).map((d) => { return d.innerText })
    let format_checked = Array.from(format_options).map((d) => { return document.getElementById(d.htmlFor).checked })
    let format_filt = [];
    format_labs.forEach((d, i) => {
        if(format_checked[i]) { format_filt.push(d) }
    });

    let format_picks;
    if(format_filt[0] == "Round 1 & 2") {
        format_picks = 60;
    } 
    else {
        format_picks = 30;
    }

    // Pick delay
    let delay_options = document.getElementsByClassName("pick-delay");
    let delay_labs = Array.from(delay_options).map((d) => { return d.innerText })
    let delay_checked = Array.from(delay_options).map((d) => { return document.getElementById(d.htmlFor).checked })
    let delay_filt = [];
    delay_labs.forEach((d, i) => {
        if(delay_checked[i]) { delay_filt.push(d) }
    });

    let delay_sec;
    if(delay_filt[0] == "1 sec") {
        delay_sec = 1;
    } 
    else if(delay_filt[0] == "2 sec") {
        delay_sec = 2;
    } 
    else if(delay_filt[0] == "3 sec") {
        delay_sec = 3;
    }

    return {
        teams: Array.from(team_options).map((d) => { return d.innerText }), 
        sources: sources_filt, 
        picks: format_picks, 
        delay: delay_sec
    }
}

let draft_order = [
    "CHA", "DET", "HOU", "ORL", "WAS", "UTA", "SAS", "IND", "CHI", "POR", 
    "OKC", "BKN", "TOR", "MIN", "ATL", "NYK", "SAC", "NOP", "CLE", "MEM", 
    "MIA", "LAC", "DAL", "PHI", "GSW", "LAL", "PHX", "MIL", "BOS", "DEN", 
    "CHA", "DET", "HOU", "ORL", "WAS", "UTA", "SAS", "IND", "CHI", "POR", 
    "OKC", "BKN", "TOR", "MIN", "ATL", "NYK", "SAC", "NOP", "CLE", "MEM", 
    "MIA", "LAC", "DAL", "PHI", "GSW", "LAL", "PHX", "MIL", "BOS", "DEN"
];

let forfeits = [53];

d3.select("#draft-teams")
    .selectAll("option")
    .data(d3.map(draft_order, d => { return d }).keys().sort())
    .enter()
    .append("option")
    .attr("value", (d) => { return d })
    .text((d) => { return d });

d3.select("#draft-teams")
    .insert("option", ":first-child")
    .attr("value", "")
    .text("Select Teams");




//<option value="" disabled selected>Select Teams</option>
dselect(document.querySelector('#draft-teams'));