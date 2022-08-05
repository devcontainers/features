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
exports.generateTemplateDocumentation = exports.generateFeaturesDocumentation = void 0;
const fs = __importStar(require("fs"));
const core = __importStar(require("@actions/core"));
const path = __importStar(require("path"));
const utils_1 = require("./utils");
const FEATURES_README_TEMPLATE = `
# #{Name}

#{Description}

## Example Usage

\`\`\`json
"features": {
        "#{Nwo}/#{Id}@#{VersionTag}": {
            "version": "latest"
        }
}
\`\`\`

## Options

#{OptionsTable}

---

_Note: This file was auto-generated from the [devcontainer-feature.json](#{RepoUrl})._
`;
const TEMPLATE_README_TEMPLATE = `
# #{Name}

#{Description}

## Options

#{OptionsTable}
`;
function generateFeaturesDocumentation(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        yield _generateDocumentation(basePath, FEATURES_README_TEMPLATE, 'devcontainer-feature.json');
    });
}
exports.generateFeaturesDocumentation = generateFeaturesDocumentation;
function generateTemplateDocumentation(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        yield _generateDocumentation(basePath, TEMPLATE_README_TEMPLATE, 'devcontainer-template.json');
    });
}
exports.generateTemplateDocumentation = generateTemplateDocumentation;
function _generateDocumentation(basePath, readmeTemplate, metadataFile) {
    return __awaiter(this, void 0, void 0, function* () {
        const directories = fs.readdirSync(basePath);
        yield Promise.all(directories.map((f) => __awaiter(this, void 0, void 0, function* () {
            var _a, _b, _c;
            if (!f.startsWith('.')) {
                const readmePath = path.join(basePath, f, 'README.md');
                // Reads in feature.json
                const jsonPath = path.join(basePath, f, metadataFile);
                if (!fs.existsSync(jsonPath)) {
                    core.error(`${metadataFile} not found at path '${jsonPath}'`);
                    return;
                }
                let parsedJson = undefined;
                try {
                    parsedJson = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
                }
                catch (err) {
                    core.error(`Failed to parse ${jsonPath}: ${err}`);
                    return;
                }
                if (!parsedJson || !(parsedJson === null || parsedJson === void 0 ? void 0 : parsedJson.id)) {
                    core.error(`${metadataFile} for '${f}' does not contain an 'id'`);
                    return;
                }
                const srcInfo = (0, utils_1.getGitHubMetadata)();
                const ref = srcInfo.ref;
                const owner = srcInfo.owner;
                const repo = srcInfo.repo;
                // Add tag if parseable
                let versionTag = 'latest';
                if (ref && ref.includes('refs/tags/')) {
                    versionTag = ref.replace('refs/tags/', '');
                }
                const generateOptionsMarkdown = () => {
                    const options = parsedJson === null || parsedJson === void 0 ? void 0 : parsedJson.options;
                    if (!options) {
                        return '';
                    }
                    const keys = Object.keys(options);
                    const contents = keys
                        .map(k => {
                        const val = options[k];
                        return `| ${k} | ${val.description || '-'} | ${val.type || '-'} | ${val.default || '-'} |`;
                    })
                        .join('\n');
                    return '| Options Id | Description | Type | Default Value |\n' + '|-----|-----|-----|-----|\n' + contents;
                };
                let urlToConfig = './devcontainer-feature.json';
                const basePathTrimmed = basePath.startsWith('./') ? basePath.substring(2) : basePath;
                if (srcInfo.owner && srcInfo.repo) {
                    urlToConfig = `https://github.com/${srcInfo.owner}/${srcInfo.repo}/blob/main/${basePathTrimmed}/${f}/devcontainer-feature.json`;
                }
                const newReadme = readmeTemplate
                    // Templates & Features
                    .replace('#{Id}', parsedJson.id)
                    .replace('#{Name}', parsedJson.name ? `${parsedJson.name} (${parsedJson.id})` : `${parsedJson.id}`)
                    .replace('#{Description}', (_a = parsedJson.description) !== null && _a !== void 0 ? _a : '')
                    .replace('#{OptionsTable}', generateOptionsMarkdown())
                    // Features Only
                    .replace('#{Nwo}', `${owner}/${repo}`)
                    .replace('#{VersionTag}', versionTag)
                    // Templates Only
                    .replace('#{ManifestName}', (_c = (_b = parsedJson === null || parsedJson === void 0 ? void 0 : parsedJson.image) === null || _b === void 0 ? void 0 : _b.manifest) !== null && _c !== void 0 ? _c : '')
                    .replace('#{RepoUrl}', urlToConfig);
                // Remove previous readme
                if (fs.existsSync(readmePath)) {
                    fs.unlinkSync(readmePath);
                }
                // Write new readme
                fs.writeFileSync(readmePath, newReadme);
            }
        })));
    });
}
