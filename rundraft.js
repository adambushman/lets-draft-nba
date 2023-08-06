class runDraft {

    constructor(teams_chosen, sources_chosen, format_chosen, delay_chosen) {
        this.teams = teams_chosen;
        this.sources = sources_chosen;
        this.format = format_chosen;
        this.pick_delay = delay_chosen;

        this.next_pick = 1;
        this.confirmed = [];
        this.left_over = [];

        this.prob_board = [];
        this.max_rank = [];
        this.team_data = [];
    }

    setNextPick() {
        this.next_pick += 1;
    }

    setConfirmedPick(name) {
        this.confirmed.push(name);
    }

    addLeftOver(name) {
        let i = this.left_over.indexOf(name);
        if(i == -1) {
            this.left_over.push(name)
        }
    }

    removeLeftOver(name) {
        let i = this.left_over.indexOf(name);
        if(i != -1) {
            this.left_over.splice(i, 1);
        }
    }

    setTeamData(data) {
        this.team_data = data;
    }

    setProbBoard(data) {
        this.prob_board = data;
    }

    setMaxRank(data) {
        this.max_rank = data;
    }
}