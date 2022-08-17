"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensureDevcontainerCliPresent = exports.isDevcontainerCliAvailable = exports.getGitHubMetadata = exports.renameLocal = exports.mkdirLocal = exports.writeLocalFile = exports.readLocalFile = void 0;
const github = __importStar(require("@actions/github"));
const fs = __importStar(require("fs"));
const util_1 = require("util");
const core = __importStar(require("@actions/core"));
const exec = __importStar(require("@actions/exec"));
exports.readLocalFile = (0, util_1.promisify)(fs.readFile);
exports.writeLocalFile = (0, util_1.promisify)(fs.writeFile);
exports.mkdirLocal = (0, util_1.promisify)(fs.mkdir);
exports.renameLocal = (0, util_1.promisify)(fs.rename);
function getGitHubMetadata() {
    // Insert github repo metadata
    const ref = github.context.ref;
    let metadata = {
        owner: github.context.repo.owner,
        repo: github.context.repo.repo,
        ref,
        sha: github.context.sha
    };
    // Add tag if parseable
    if (ref.includes('refs/tags/')) {
        const tag = ref.replace('refs/tags/', '');
        metadata = Object.assign(Object.assign({}, metadata), { tag });
    }
    return metadata;
}
exports.getGitHubMetadata = getGitHubMetadata;
function isDevcontainerCliAvailable(cliDebugMode = false) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            let cmd = 'devcontainer';
            let args = ['--version'];
            if (cliDebugMode) {
                cmd = 'npx';
                args = ['-y', './devcontainer.tgz', ...args];
            }
            const res = yield exec.getExecOutput(cmd, args, {
                ignoreReturnCode: true,
                silent: true
            });
            core.info(`Devcontainer CLI version '${res.stdout}' is installed.`);
            return res.exitCode === 0;
        }
        catch (err) {
            return false;
        }
    });
}
exports.isDevcontainerCliAvailable = isDevcontainerCliAvailable;
function ensureDevcontainerCliPresent(cliDebugMode = false) {
    return __awaiter(this, void 0, void 0, function* () {
        if (yield isDevcontainerCliAvailable(cliDebugMode)) {
            core.info('devcontainer CLI is already installed');
            return true;
        }
        if (cliDebugMode) {
            core.error('Cannot remotely fetch CLI in debug mode');
            return false;
        }
        try {
            core.info('Fetching the latest @devcontainer/cli...');
            const res = yield exec.getExecOutput('npm', ['install', '-g', '@devcontainers/cli'], {
                ignoreReturnCode: true,
                silent: true
            });
            return res.exitCode === 0;
        }
        catch (err) {
            return false;
        }
    });
}
exports.ensureDevcontainerCliPresent = ensureDevcontainerCliPresent;
