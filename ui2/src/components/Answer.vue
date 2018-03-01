<template>
  <div>
    <div class="answers">
      <div v-if="isAdmin || isWriter" class="scoring">
        <div class="row">
          <div class="col-6">
            <input v-model="newPoint" type="number" class="form-control">
          </div>
          <div class="col-6">
            <input type="checkbox" id="checkbox" v-model="solved">
            <label for="checkbox">基準</label>
            <button v-on:click="submitPoint()" type="submit" class="btn btn-primary">採点</button>
          </div>
        </div>
      </div>
      <div v-if="value" class="answer">
        <markdown :value="value.text"></markdown>
        <div class="meta">
          <small>{{ value.created_at }}</small>
        </div>
      </div>
      <div class="status">
        <template>
          <div v-if="value.score" class="result">
            得点: {{ value.score.point }} + ボーナス: {{ value.score.bonus_point }}
          </div>
          <div v-if="!value.score && !isStaff && isContestEnded" class="pending">競技時間が終了したため表示されません</div>
          <div v-if="!value.score && (isStaff || !isContestEnded)" class="pending">採点依頼中...</div>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.answers {
  border: 1px solid #fdbbcc;
  padding: 1rem;
  padding-bottom: 0;
  margin-bottom: 2rem;
}
.answer {
  margin-bottom: 1rem;
}
.status {
  margin: 0 -1rem;
  text-align: center;
}
.status .pending {
  background: #fdbbcc;
  color: white;
  padding: .5rem;
}
.status .result {
  background: #ed1848;
  color: white;
  padding: .5rem;
}
.status .send {
  padding: .5rem;
  margin: auto;
  width: 15rem;
}

.scoring {
}
</style>

<script>
import SimpleMarkdownEditor from '../components/SimpleMarkdownEditor'
import Markdown from '../components/Markdown'
import { Emit, PUSH_NOTIF, REMOVE_NOTIF } from '../utils/EventBus'
import { API } from '../utils/Api'
import { mapGetters } from 'vuex'

export default {
  name: 'answer',
  components: {
    SimpleMarkdownEditor,
    Markdown,
  },
  props: {
    value: Object,
    reload: Function,
  },
  data () {
    return {
      post: '',
      newPoint: undefined,
      now: new Date(),
    }
  },
  asyncData: {
  },
  computed: {
    issueId () {
      return this.value.id;
    },
    isContestEnded () {
      if (!this.contest || !this.contest.competition_end_at) return false;
      return new Date(this.contest.competition_end_at) <= this.now;
    },
    ...mapGetters([
      'contest',
      'isAdmin',
      'isWriter',
      'isStaff',
    ]),
  },
  watch: {
    value (val) {
      this.newPoint = (this.value.score && this.value.score.point) || 0;
      this.solved = (this.value.score && this.value.score.solved) || false;
    },
  },
  mounted () {
    this.newPoint = (this.value.score && this.value.score.point) || 0;
    this.solved = (this.value.score && this.value.score.solved) || false;
    this.interval_id = setInterval(() => { this.now = new Date() }, 1000);
  },
  destroyed () {
    clearInterval(this.interval_id);
  },
  methods: {
    submitPoint () {
      Emit(REMOVE_NOTIF, msg => msg.key === 'answer');

      var postOrPut;
      if (this.value.score && this.value.score.id) {
        postOrPut = API.putScore(this.value.score.id, Object.assign({}, this.value.score, {
          point: this.newPoint,
          solved: this.solved,
        }))
      } else {
        postOrPut = API.postScore(this.value.id, this.newPoint, this.solved)
      }

      postOrPut
        .then(res => {
          console.log('Patch OK');
          Emit(PUSH_NOTIF, {
            type: 'success',
            icon: 'check',
            title: '得点を更新しました',
            detail: '',
            key: 'issue',
            autoClose: true,
          });
          if (this.reload.apply) this.reload();
        })
        .catch(err => {
          console.error(err);
          Emit(PUSH_NOTIF, {
            type: 'error',
            icon: 'warning',
            title: '得点の更新に失敗しました',
            key: 'issue',
            autoClose: false,
          });
        })
    },
  },
}
</script>

