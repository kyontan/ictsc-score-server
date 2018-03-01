<template>
  <div>
    <div v-if="isAdmin || isWriter" class="fixed-tool-tips">
      <div v-on:click="showAddGroup = true" class="add"><i class="fa fa-plus"></i>新規グループ</div>
      <div v-on:click="showAddProblem = true" class="add"><i class="fa fa-plus"></i>新規問題</div>
    </div>
    <message-box v-model="showAddProblem">
      <span slot="title">新規問題</span>
      <div slot="body">
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">タイトル</label>
          <div class="col-sm-9">
            <input v-model="newProblemObj.title" type="text" class="form-control" placeholder="タイトル">
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">担当者</label>
          <div class="col-sm-9">
            <select class="form-control" v-model="newProblemObj.creator_id">
              <option v-for="member in memberSelect" v-if="member.role_id===3" :value="member.id">{{ member.name }}</option>
            </select>
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">基準点</label>
          <div class="col-sm-9">
            <input v-model="newProblemObj.reference_point" type="number" class="form-control">
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">満点</label>
          <div class="col-sm-9">
            <input v-model="newProblemObj.perfect_point" type="number" class="form-control">
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">依存問題</label>
          <div class="col-sm-9">
            <select class="form-control" v-model="newProblemObj.problem_must_solve_before_id">
              <option v-for="problem in problemSelect" :value="problem.id">{{ problem.title }}</option>
            </select>
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">グループ<br />(複数選択可)</label>
          <div class="col-sm-9">
            <select class="form-control" v-model="newProblemObj.problem_group_ids" multiple>
              <option v-for="group in problemGroups" :value="group.id">{{ group.name }}</option>
            </select>
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">表示順序<br/>(低いほうが先)</label>
          <div class="col-sm-9">
            <input v-model="newProblemObj.order" type="number" class="form-control">
          </div>
        </div>

        <simple-markdown-editor v-model="newProblemObj.text"></simple-markdown-editor>
      </div>
      <template slot="buttons" scope="props">
        <button v-on:click="addProblem()" class="btn btn-lg btn-success">
          <i class="fa fa-plus"></i> 問題を追加する
        </button>
      </template>
    </message-box>
    <message-box v-model="showAddGroup">
      <span slot="title">新規グループ</span>
      <div slot="body">
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">グループ名</label>
          <div class="col-sm-9">
            <input v-model="newGroupObj.name" type="text" class="form-control" placeholder="グループ名">
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">表示する</label>
          <div class="col-sm-9">
            <select v-model="newGroupObj.visible" class="form-control" name="visibility">
              <option :value="1">はい</option>
              <option :value="0">いいえ</option>
            </select>
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">完答ボーナス</label>
          <div class="col-sm-9">
            <input v-model="newGroupObj.completing_bonus_point" type="number" class="form-control" placeholder="完答ボーナス">
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-3 col-form-label">国旗</label>
          <div class="col-sm-9">
            <input v-model="newGroupObj.flag_icon_url" type="text" class="form-control" placeholder="http://">
          </div>
        </div>
        <simple-markdown-editor v-model="newGroupObj.description"></simple-markdown-editor>
      </div>
      <template slot="buttons" scope="props">
        <button v-on:click="addGroup()" class="btn btn-lg btn-success">
          <i class="fa fa-plus"></i> グループを追加する
        </button>
      </template>
    </message-box>

    <h1>問題一覧</h1>
    <div class="description">
      <p>
        各部署に複数の問題があります。
      </p>
      <p>
        それぞれの問題に設定された基準を満たすと、次の問題が解放されます。
      </p>

      <div class="steps d-flex">
        <div class="item">
          <h4>各部署から問題を選んで解答</h4>
          <p>解放されている問題を選択し、解答を行ってください。</p>
        </div>
        <div class="item">
          <h4>運営が採点 (20分間)</h4>
          <p>運営が採点中はその問題を解けません。</p>
        </div>
        <div class="item">
          <h4>採点結果を確認</h4>
          <p>満点でない場合は、高得点を目指して追加の解答も可能です。</p>
        </div>
      </div>
      <div class="alert alert-warning" role="alert">
        <h4 class="alert-heading">問題解答の注意点</h4>
        <ul>
          <li>採点結果は、採点依頼を送信してから20分後に返ってきます。</li>
          <li>採点中はその問題へ新たに解答することはできません。</li>
        </ul>
      </div>
    </div>

    <div v-loading="asyncLoading" class="groups">
      <div v-for="group in problemGroups" v-if="group.visible" class="group">
        <div class="detail">
          <img class="flag" v-if="group.flag_icon_url" :src="group.flag_icon_url">
          <h2>{{ group.name }}</h2>
          <markdown :value="group.description"></markdown>
        </div>
        <div class="problems d-flex flex-row align-content-center flex-nowrap">
          <template v-for="problem in sortedProblems" v-if="problem.problem_group_ids.includes(group.id)">
            <div class="arrow-next-problem"></div>
            <router-link
              :to="{ name: 'problem-detail', params: { id: '' + problem.id } }"
              class="problem d-flex flex-column align-items-stretch">
              <div class="background"></div>
              <div class="background-triangle"></div>
              <div class="background-sealing-icon" v-if="problemGroupIconSrc(problem)"><img :src="problemGroupIconSrc(problem)"></div>
              <div v-if="problem.title === undefined" class="overlay">
                <div class="overlay-message">
                  <div>{{ problemUnlockConditionTitle(problem.problem_must_solve_before_id) }}で解放</div>
                </div>
              </div>
              <h3>{{ problem.title }}<a v-if="isStaff">({{ problem.creator.name }})</a></h3>
              <div class="bottom-wrapper d-flex align-content-end align-items-end mt-auto">
                <div class="scores-wrapper mr-auto">
                  <div class="scores" v-if="isMember">
                    <div class="current">得点 <span class="subtotal">{{ getScoreInfo(problem.answers).subtotal }}</span><span class="perfect_point"> / {{ problem.perfect_point }}</span></div>
                    <div class="border"></div>
                    <span class="brakedown">内訳</span>
                    <div class="point">基本点 {{ getScoreInfo(problem.answers).pure }}</div>
                    <div class="point">ボーナス点 {{ getScoreInfo(problem.answers).bonus }}</div>
                  </div>
                  <div class="scores" v-if="isStaff">
                    <div class="border"></div>
                    <div class="brakedown">内訳</div>
                    <div class="point">満点 {{ problem.perfect_point }}</div>
                    <div class="point">基準点 {{ problem.reference_point }}</div>
                  </div>
                </div>
                <div class="tips ml-auto">
                  <div v-if="isMember"><i class="fa fa-paper-plane-o"></i> {{ scoringStatusText(problem) }}</div>
                  <div><i class="fa fa-child"></i> {{ problem.solved_teams_count }}チーム正解</div>
                </div>
              </div>
            </router-link>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.fixed-tool-tips {
  position: fixed;
  top: 5rem;
  right: 3rem;
  z-index: 1;
}
.fixed-tool-tips > * {
  cursor: pointer;
  padding: 1rem;
  background: #888;
  color: white;
  line-height: 1;
  border-radius: 2rem;
  font-size: 1.2rem;
  margin-bottom: 5px;
}

.add > .fa {
  padding-right: 5px;
}

.groups {
  min-height: 15rem;
}
.group {
  border-top: 1px solid #ccc;
  padding: 2rem;
}
.group h2 {
  display: inline-block;
  color: #FDBBCC;
  font-size: 2.5rem;
}
.group .flag {
  height: 38px;
  margin-right: .2em;
  vertical-align: top;
}

.group .detail {
  width: 100%;
}

.problems {
  align-items: center;
  margin-top: 1em;
  overflow-x: auto;
}

.problem .background {
  z-index: -998;
  position: absolute;
  width: 100%;
  height: 100%;
  border: 4px solid white;
}

.problem .background-triangle {
  z-index: -999;
  position: absolute;
  /*width: calc(100% - 10px);*/
  /*margin: 10% 5px 0;*/
  /*height: 20%;*/
  /*background: #E7EFF1;*/

  content: '';
  width: 0;
  height: 0;
  margin: 0 0 0 -63px;
  border-style: solid;
  border-width: 80px 230px 0;
  border-color: #E7EFF1 transparent transparent transparent;
}

.problem .background-sealing-icon {
  z-index: -997;
  position: absolute;
  margin: 50px calc(50% - 24px) 0;
}

.problem .background-sealing-icon img {
  width: 48px;
  height: 48px;
}

.problem {
  border: 1px solid #d9d9d9;
  overflow: hidden;
  flex-wrap: nowrap;
  position: relative;
  display: block;
  color: inherit;
  text-decoration: none;

  min-height: 13em;
  max-height: 13em;
  min-width: 23em;
  max-width: 24em;

  flex: 1;
}

.problem h3 {
  margin: 14px;
  overflow-wrap: break-word;
  font-size: 1.3em;
}

.problems .problem + .arrow-next-problem {
  content: '';
  width: 0;
  height: 0;
  margin: 0 10px;
  border-style: solid;
  border-width: 14px 0 14px 15px;
  border-color: transparent transparent transparent #e0e0e0;
}

.problem .bottom-wrapper {
  margin: 10px;
}

.problem .scores-wrapper {
  min-width: 10em;
  text-align: right;
}

.problem .scores {
  font-size: .96em;
}

.problem .scores .current {
  font-size: 1.15em;
  font-weight: bold;
  margin-bottom: 0;
  color: #E6003B;
}

.problem .scores .perfect_point {
  font-size: 1.06em;
}

.problem .scores .current .subtotal {
  font-size: 1.8em;
}

.problem .scores .brakedown, .problem .scores .point {
  color: #DDDDDD;
}

.problem .scores .border {
  border-top: 1px solid #DDDDDD;
}

.problem .scores .brakedown {
  float: left;
}

.problem .tips {
  float: right;
  font-size: 1.1em;
  text-align: right;
  width: calc(50% - 10px);
}

.problem .overlay {
  position: absolute;
  background: rgba(19,37,48,0.7);
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
}
.problem .overlay .overlay-message {
  color: white;
  font-size: 1.2em;
  line-height: 1.5;
  font-weight: bold;
  flex-grow: 1;
  text-align: center;
  margin: auto 1em;
}

.description {
  margin-bottom: 2rem;
}

.steps {
  margin: 2rem 0;
}
.steps .item {
  flex-grow: 1;
  min-width: 5rem;
  padding: 1rem;
  padding-right: 4rem;
  background: #efefef;
  position: relative;
  background-image: url('../assets/img/arrow.svg');
  background-repeat: repeat-y;
  background-position: right center;
}
.steps .item:last-child {
  background-image: none;
  padding-right: 1rem;
}
.steps .item p {
  margin: 0;
}
</style>

<script>
import { SET_TITLE } from '../store/'
import { API } from '../utils/Api'
import Markdown from '../components/Markdown'
import MessageBox from '../components/MessageBox'
import SimpleMarkdownEditor from '../components/SimpleMarkdownEditor'
import { mapGetters } from 'vuex'
import { Emit, PUSH_NOTIF, REMOVE_NOTIF } from '../utils/EventBus'
import { dateRelative } from '../utils/Filters'

export default {
  name: 'problems',
  components: {
    Markdown,
    MessageBox,
    SimpleMarkdownEditor,
  },
  filters: {
    dateRelative,
  },
  data () {
    return {
      showAddProblem: false,
      showAddGroup: false,
      newProblemObj: {
        title: '',
        text: '',
        creator_id: null,
        reference_point: 0,
        perfect_point: 0,
        problem_group_ids: [],
        order: 0,
        problem_must_solve_before_id: null,
      },
      newGroupObj: {
        name: '',
        description: '',
        visible: 1,
        completing_bonus_point: 0,
        flag_icon_url: '',
      },
      newMemberObj: {
        name: '',
      },
    }
  },
  asyncData: {
    problemGroupsDefault: [],
    problemGroups () {
      return API.getProblemGroups();
    },
    problemsDefault: [],
    problems () {
      if (this.session.member) {
        if (this.isMember || this.isStaff) {
          return API.getProblemsWithScore();
        } else {
          return API.getProblems();
        }
      } else {
        return new Promise((resolve) => resolve([]));
      }
    },
    membersDefault: [],
    members () {
      return API.getMembers();
    },
  },

  computed: {
    sortedProblems () {
      return this.problems.sort((p1, p2) => p1.order - p2.order);
    },
    problemSelect () {
      return Array.concat([{
        id: null,
        title: 'Null',
      }], this.problems);
    },
    ...mapGetters([
      'contest',
      'isAdmin',
      'isStaff',
      'isMember',
      'isWriter',
      'session',
    ]),
    memberSelect () {
      return Array.concat([{
        id: null,
        name: 'Null',
        role_id: null,
      }], this.members);
    },
  },
  watch: {
    problemGroups (val) {
      try {
        this.newObj.problem_group_id = val[0].id;
      } catch (e) {
      }
    },
    session (val) {
      if (val.member) this.asyncReload('problems');
    },
  },
  mounted () {
    this.$store.dispatch(SET_TITLE, '問題一覧');
  },
  destroyed () {
  },
  methods: {
    scoringStatusText (problem) {
      if (problem.title === undefined) {
        return '解答不可'
      }

      let answers = problem.answers;
      if (!answers || answers.length === 0) {
        return '解答可能'
      } else {
        var createdAt = answers[answers.length - 1].created_at;
        var publishAt = new Date(createdAt).valueOf() +
          (this.contest ? this.contest.answer_reply_delay_sec * 1000 : 0);

        if (publishAt < new Date()) {
          return '解答可能'
        } else {
          return `${dateRelative(publishAt)}に解答送信可`;
        }
      }
    },
    getScoreInfo (answers) {
      let nothing = {
        pure: 0,
        bonus: 0,
        subtotal: 0,
      }
      if (!this.session.member) return nothing;
      if (!answers) return nothing;
      if (this.contest && (new Date(this.contest.competition_end_at) < Date.now())) return nothing;
      return answers
        .reduce((p, n) => ({
          pure: p.pure + ((n.score && n.score.point) || 0),
          bonus: p.bonus + ((n.score && n.score.bonus_point) || 0),
          subtotal: p.subtotal + ((n.score && n.score.subtotal_point) || 0),
        }), {
          pure: 0,
          bonus: 0,
          subtotal: 0,
        });
    },
    problemUnlockConditionTitle (id) {
      var found = this.problems.find(p => p.id === id);
      if (found && found.title) return `「${found.title}」で基準を満たすチームが表われること`;
      if (found) return '前の問題で基準を満たすチームが表われること';
      else return '前の問題';
    },
    problemGroupIconSrc (problem) {
      let pg = this.problemGroups.find(pg => !pg.visible && pg.problem_ids.includes(problem.id));

      if (!pg) return null;
      return pg.flag_icon_url;
    },
    async addProblem () {
      try {
        Emit(REMOVE_NOTIF, msg => msg.key === 'problem');
        await API.postProblems(this.newProblemObj);
        this.newProblemObj.title = '';
        this.newProblemObj.text = '';
        Emit(PUSH_NOTIF, {
          type: 'success',
          title: '投稿しました',
          detail: '',
          key: 'problem',
        });
        this.asyncReload('problems');
      } catch (err) {
        console.log(err)
        Emit(PUSH_NOTIF, {
          type: 'error',
          title: '投稿に失敗しました',
          detail: '',
          key: 'problem',
        });
      }
    },
    async addGroup () {
      try {
        Emit(REMOVE_NOTIF, msg => msg.key === 'problemGroup');
        await API.postProblemGroup(this.newGroupObj);
        this.newGroupObj.name = '';
        this.newGroupObj.description = '';
        Emit(PUSH_NOTIF, {
          type: 'success',
          title: '投稿しました',
          detail: '',
          key: 'problemGroup',
        });
        this.asyncReload('problemGroups');
      } catch (err) {
        console.log(err)
        Emit(PUSH_NOTIF, {
          type: 'error',
          title: '投稿に失敗しました',
          detail: '',
          key: 'problemGroup',
        });
      }
    },
  },
}
</script>
