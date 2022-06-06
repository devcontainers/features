"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTemplatesAndPackage = exports.getFeaturesAndPackage = exports.addCollectionsMetadataFile = exports.tarDirectory = exports.renameLocal = exports.mkdirLocal = exports.writeLocalFile = exports.readLocalFile = void 0;
const github = __importStar(require("@actions/github"));
const tar = __importStar(require("tar"));
const fs = __importStar(require("fs"));
const core = __importStar(require("@actions/core"));
const util_1 = require("util");
const path_1 = __importDefault(require("path"));
exports.readLocalFile = (0, util_1.promisify)(fs.readFile);
exports.writeLocalFile = (0, util_1.promisify)(fs.writeFile);
exports.mkdirLocal = (0, util_1.promisify)(fs.mkdir);
exports.renameLocal = (0, util_1.promisify)(fs.rename);
// Filter what gets included in the tar.c
const filter = (file, _) => {
    // Don't include the archive itself.
    if (file === './devcontainer-features.tgz') {
        return false;
    }
    return true;
};
function tarDirectory(path, tgzName) {
    return __awaiter(this, void 0, void 0, function* () {
        return tar.create({ file: tgzName, C: path, filter }, ['.']).then(_ => {
            core.info(`Compressed ${path} directory to file ${tgzName}`);
        });
    });
}
exports.tarDirectory = tarDirectory;
function addCollectionsMetadataFile() {
    return __awaiter(this, void 0, void 0, function* () {
        const p = path_1.default.join('.', 'devcontainer-collection.json');
        // Insert github repo metadata
        const ref = github.context.ref;
        let sourceInformation = {
            source: 'github',
            owner: github.context.repo.owner,
            repo: github.context.repo.repo,
            ref,
            sha: github.context.sha
        };
        // Add tag if parseable
        if (ref.includes('refs/tags/')) {
            const tag = ref.replace('refs/tags/', '');
            sourceInformation = Object.assign(Object.assign({}, sourceInformation), { tag });
        }
        const metadata = {
            sourceInformation,
            features: [],
            templates: []
        };
        // Write to the file
        yield (0, exports.writeLocalFile)(p, JSON.stringify(metadata, undefined, 4));
    });
}
exports.addCollectionsMetadataFile = addCollectionsMetadataFile;
function getFeaturesAndPackage(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        let archives = [];
        fs.readdir(basePath, (err, files) => {
            if (err) {
                core.error(err.message);
                core.setFailed(`failed to get list of features: ${err.message}`);
                return;
            }
            files.forEach(file => {
                core.info(`feature ==> ${file}`);
                if (file !== '.' && file !== '..') {
                    const archiveName = `${file}.tgz`;
                    tarDirectory(`${basePath}/${file}`, archiveName);
                    archives.push(archiveName);
                }
            });
        });
        return archives;
    });
}
exports.getFeaturesAndPackage = getFeaturesAndPackage;
function getTemplatesAndPackage(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        let archives = [];
        fs.readdir(basePath, (err, files) => {
            if (err) {
                core.error(err.message);
                core.setFailed(`failed to get list of templates: ${err.message}`);
                return;
            }
            files.forEach(file => {
                core.info(`template ==> ${file}`);
                if (file !== '.' && file !== '..') {
                    const archiveName = `devcontainer-definition-${file}.tgz`;
                    tarDirectory(`${basePath}/${file}`, archiveName);
                    archives.push(archiveName);
                }
            });
        });
        return archives;
    });
}
exports.getTemplatesAndPackage = getTemplatesAndPackage;
