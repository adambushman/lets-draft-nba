class runDraft {

    constructor(teams_chosen, sources_chosen, format_chosen, delay_chosen) {
        this.teams = teams_chosen;
        this.sources = sources_chosen;
        this.format = format_chosen;
        this.pick_delay = delay_chosen;

        this.next_pick = 1;
        this.confirmed = [];

        this.prob_board = [];
        this.max_rank = [];
        this.team_data = [];
    }

    // Setters
    setNextPick() {
        this.next_pick += 1;
    }

    setConfirmedPick(name) {
        this.confirmed.push(name);
    }

    setTeamData(data) {
        this.team_data = data;
    }
}