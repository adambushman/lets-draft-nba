let filters = getFilters();

let mydraft = new runDraft();

function sample(x, n, replace, prob) {
    let my_table = aq.table({val: x, prob: prob})
        .derive({rng: d => op.sequence(1, op.round(d.prob * 100) + 1)})
        .unroll("rng");

    let my_sample = my_table.sample(n, {replace: replace});
    return(my_sample.columnArray("val"));
}


// Get max rank
function getMaxRank(name) {
    let df = aq.from(mydraft.max_rank)
        .filter(aq.escape(d => d.Player == name))
        .objects();
    
    return(df[0].maxx)
}

// Looping functions

function simNextPicks() {
    while(mydraft.next_pick <= mydraft.format & !mydraft.teams.includes(draft_order[mydraft.next_pick - 1])) {
        let comp_pick = [];
        let players = [];

        // Check for players who are at the end of their draft range
        if(mydraft.left_over.length > 0) {
            if(getMaxRank(mydraft.left_over[0]) >= (mydraft.next_pick - 1)) {
                comp_pick = [mydraft.left_over[0]];

                // Setup left over players
                players = aq.from(mydraft.prob_board)
                    .filter(aq.escape(d => d.pick == (mydraft.next_pick - 1)))
                    .objects()[0]
                    .players;
            }
        } 
        if (comp_pick.length == 0) {
            
            // Remove already picked players
            let curr_pos = mydraft.prob_board[mydraft.next_pick - 1];
            let available = aq.table({players: curr_pos.players, probs: curr_pos.probabilities})
                .filter(aq.escape(d => !mydraft.confirmed.includes(d.players)))
                .objects();

            let probabilities = [];
            available.forEach(d => { 
                players.push(d.players);
                probabilities.push(d.probs);
            });

            comp_pick = sample(players, 1, false, probabilities);
        }

        // Draft message
        console.log(`${draft_order[mydraft.next_pick - 1]} has selected ${comp_pick} at ${mydraft.next_pick}`);
        
        // Clean up picks
        mydraft.setConfirmedPick(comp_pick[0]);
        players.forEach(d => {
            if(!mydraft.confirmed.includes(d)) {
                mydraft.addLeftOver(d);
            }
        });
        mydraft.removeLeftOver(comp_pick[0]);
        mydraft.setNextPick();
    }

    if(mydraft.next_pick > mydraft.format) {
        console.log("End of sim");
        return;
    }
    // User draft message
    console.log(`You must pick for ${draft_order[mydraft.next_pick - 1]} at ${mydraft.next_pick}!!`);

    let teamOnDeck = mydraft.team_data.filter(d => {return d.abbreviation == draft_order[mydraft.next_pick - 1]})[0];

    // Update the logo
    let logo = d3.select("#team-logo");
    logo.select("img").remove();
    logo.append("img").attr("src", teamOnDeck.logo).attr("class", "img-fluid");

    // Update the text
    d3.select("#modal-pick-no").text(mydraft.next_pick);

    // Update the players to select
    let remaining = aq.from(mydraft.max_rank)
        .filter(aq.escape(d => !mydraft.confirmed.includes(d.Player)))
        .filter(d => d.Player != '')
        .objects();
    
    pushSelections(remaining);

    $(document).ready(function(){
        $("#exampleModal").modal("show");
    });
}

function makeUserPick() {
    // Setup left over players
    let players = aq.from(mydraft.prob_board)
        .filter(aq.escape(d => d.pick == (mydraft.next_pick - 1)))
        .objects()[0]
        .players;

    players.forEach(d => {
        if(!mydraft.confirmed.includes(d)) {
            mydraft.addLeftOver(d);
        }
    })

    // Make the selection
    let dropdown = document.querySelector("#draft-players");
    let user_pick = dropdown.options[dropdown.selectedIndex].text;
    console.log(`You selected ${user_pick} on behalf of ${draft_order[mydraft.next_pick - 1]} at ${mydraft.next_pick}`);

    // Clean up
    mydraft.setConfirmedPick(user_pick);
    mydraft.removeLeftOver(user_pick);
    mydraft.setNextPick();
    simNextPicks();
}

popSources();



function startDraft() {
    let filters = getFilters();
    mydraft = new runDraft(filters.teams, filters.sources, filters.picks, filters.delay);

    // console.log(filters);

    d3.csv('https://raw.githubusercontent.com/adambushman/basketball-data/master/draft/2023_Industry_Boards.csv', data => {

        d3.csv('team-reference.csv', teams => {
            mydraft.setTeamData(teams);

            let df = aq.from(data)
                .fold(
                    aq.not('Rank')
                    , {as: ['Source', 'Player']}
                )
                .derive({Rank: aq.escape(d => parseInt(d.Rank))})
                .filter(aq.escape(d => filters.sources.includes(d.Source)));

            let real_rank = df.groupby("Rank", "Player")
                .rollup({ Freq: d => op.count() })
                .filter(d => d.Player != "");

            let max_rank = df.groupby("Player")
                .rollup({
                    n_rank: d => op.count(), 
                    maxx: d => op.max(d.Rank)
                })
                .derive({rows: data.length})
                .derive({
                    m_pick: d => d.n_rank < 2 ? d.rows : op.least(d.maxx, d.rows)
                })
                .objects();

            let prob_board = real_rank.groupby("Player")
                .derive({min: d => op.min(d.Rank), max: d => op.max(d.Rank) })
                .derive({ pick: d => d.min == d.max ? [d.Rank] : op.sequence(d.min, d.max) })
                .unroll("pick")
                .derive({ Freq: d => d.Rank != d.pick ? 0.5 : d.Freq})
                .groupby("Player", "pick")
                .rollup({Freq: d => op.max(d.Freq)})
                .groupby("pick")
                .derive({freq_total: d => op.sum(d.Freq)})
                .derive({ prob: d => d.Freq / d.freq_total })
                .orderby("pick")
                .groupby("pick")
                .rollup({
                    players: d => op.array_agg(d.Player), 
                    probabilities: d => op.array_agg(d.prob)
                })
                .objects();

            // console.log(prob_board);
            // console.log(max_rank);

            mydraft.setProbBoard(prob_board);
            mydraft.setMaxRank(max_rank);

            simNextPicks();
        
        })
    })
}