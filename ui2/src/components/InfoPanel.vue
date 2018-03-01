<template>
  <div class="panel">
    <span class="limit">{{ limit | tickDuration }}</span>
    <span v-if="isMember" class="score">
      <span class="label">Progress</span>
      <span class="ratio">{{ ratio }}</span>
    </span>
  </div>
</template>

<style scoped>
.panel {
  font-family: Menlo,Monaco,Consolas,Liberation Mono,Courier New,monospace;
  background: #ed1848;
  color: #fff;
  position: fixed;
  bottom: 0;
  left: 0;
  min-height: 3rem;
  padding: .5rem;
  border-top-right-radius: 10px;
  z-index: 1500;
}
.limit {
  font-size: 1.5rem;
}
</style>

<script>
import { API } from '../utils/Api'
import { tickDuration, latestAnswer } from '../utils/Filters'
import * as d3 from 'd3'
import { mapGetters } from 'vuex'

export default {
  name: 'info-panel',
  filters: {
    tickDuration,
  },
  data () {
    return {
      currentDate: new Date(),
      sumPurePoint: 0,
      scoredPurePoint: 0,
    }
  },
  asyncData: {
    problemsDefault: [],
    problems () {
      return API.getProblemsWithScore();
    },
  },
  computed: {
    limit () {
      var end = this.contest.competition_end_at;
      if (end) {
        return new Date(end).valueOf() - this.currentDate.valueOf();
      } else {
        return 0
      }
    },
    ratio () {
      return d3.format('.3%')(this.scoredPurePoint / this.sumPurePoint);
    },
    ...mapGetters([
      'contest',
      'isMember',
    ]),
  },
  watch: {
    problems (val) {
      try {
        this.sumPurePoint = ((e) => e.perfect_point ? e.perfect_point : 0)(latestAnswer(val))

        var scores = answers => ((e) => e && e.score ? e.score.point : 0)(latestAnswer(answers));
        this.scoredPurePoint = val
          .reduce((p, n) => p + scores(n.answers), 0);
      } catch (err) {
        console.warn('scoredPurePoint', err);
      }
    },
  },
  mounted () {
    var refreshDate = () => setTimeout(() => {
      this.currentDate = new Date();
      refreshDate();
    }, 200);
    refreshDate();

    setInterval(() => {
      this.asyncReload();
    }, 120 * 1000);
  },
  destroyed () {
  },
  methods: {
  },
}
</script>

